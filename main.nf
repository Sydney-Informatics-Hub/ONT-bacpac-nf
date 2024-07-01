#!/usr/bin/env nextflow

// To use DSL-2 will need to include this
nextflow.enable.dsl=2

// Import processes or subworkflows to be run in the workflow
include { check_input } from './modules/check_input'
include { concat_fastqs } from './modules/concat_fq'
include { porechop } from './modules/run_porechop' 
include { pycoqc_summary } from './modules/run_pycoqc'
include { nanoplot_summary } from './modules/run_nanoplot'
include { get_ncbi } from './modules/get_ncbi'
include { get_amrfinderplus } from './modules/get_amrfinderplus'
include { get_plassembler } from './modules/get_plassembler'
include { get_kraken2 } from './modules/get_kraken2'
include { get_bakta } from './modules/get_bakta'
include { kraken2 } from './modules/run_kraken2'
include { flye_assembly } from './modules/run_flye'
include { unicycler_assembly } from './modules/run_unicycler'
include { trycycler_cluster } from './modules/run_trycycler_cluster'
include { classify_trycycler } from './modules/run_trycycler_classify'
include { trycycler_reconcile } from './modules/run_trycycler_reconcile'
include { select_assembly } from './modules/select_assembly'
include { trycycler_msa } from './modules/run_trycycler_msa'
include { trycycler_partition } from './modules/run_trycycler_partition'
include { trycycler_consensus} from './modules/run_trycycler_consensus'
include { medaka_polish_consensus } from './modules/run_medaka_polish_consensus'
include { medaka_polish_flye } from './modules/run_medaka_polish_flye'
include { plassembler } from './modules/run_plassembler'
//include { busco_annotation_plasmids } from './modules/run_busco_annotation_plasmids'
//include { busco_annotation_chromosomes } from './modules/run_busco_annotation_chromosome'
//include { bakta_annotation_plasmids } from './modules/run_bakta_annotation_plasmids'
//include { bakta_annotation_chromosomes } from './modules/run_bakta_annotation_chromosomes'
//include { abricate_virulence } from './modules/run_abricate_virulence'
//include { amrfinderplus } from './modules/run_amrfinderplus'
//include { phylogeny } from './modules/run_phylogeny'
//include { multiqc_report } from './modules/run_multiqc'

// Print a header for your pipeline 
log.info """\

=======================================================================================
O N T - B A C P A C K - nf 
=======================================================================================

Created by TODO NAME 
Find documentation @ TODO INSERT LINK
Cite this pipeline @ TODO INSERT DOI

=======================================================================================
Workflow run parameters 
=======================================================================================
input       : ${params.input}
results     : ${params.outDir}
workDir     : ${workflow.workDir}
=======================================================================================

"""

/// Help function 
// This is an example of how to set out the help function that 
// will be run if run command is incorrect or missing. 

def helpMessage() {
    log.info"""
  Usage:  nextflow run main.nf --input <path to directory> 

  Required Arguments:

  --input		Specify full path and name of directory.

  Optional Arguments:

  --outDir	Specify path to output directory. 
	
""".stripIndent()
}

// Define workflow structure. Include some input/runtime tests here.
// See https://www.nextflow.io/docs/latest/dsl2.html?highlight=workflow#workflow
workflow {

// Show help message if --help is run or (||) a required parameter (input) is not provided

if ( params.help || params.input == false ){   
// Invoke the help function above and exit
	helpMessage()
	exit 1
	// consider adding some extra contigencies here.
	// could validate path of all input files in list?
	// could validate indexes for reference exist?

// If none of the above are a problem, then run the workflow
} else {

  // DOWNLOAD DATABASES  
  get_amrfinderplus()
  get_plassembler()
  get_ncbi()
  
    // Only download kraken2 if existing db not already provided 
    if (!params.kraken2_db){
      get_kraken2()
      kraken2_db = get_kraken2.out.kraken2_db

    } else { 
      log.info "FYI: USING EXISTING KRAKEN2 DATABASE ${params.kraken2_db}"
      kraken2_db = params.kraken2_db
    }

    // Only download bakta if existing db not already provided 
    if (!params.bakta_db){
      get_bakta()

    } else { 
      log.info "FYI: USING EXISTING BAKTA DATABASE ${params.bakta_db}"
    }

	// VALIDATE INPUT DIRECTORY 
	check_input(params.input)

  // QC SUMMARY OF RAW INPUTS 
  // TODO THESE MODULES DON'T FUNCTION
  //nanoplot_summary(params.input)
  //pycoqc_summary(params.input)

	// READ SUBDIRECTORIES FROM UNZIPPED_INPUTS
	unzipped_fq_dirs = check_input.out.unzipped
                    .flatten()
                    .map { path ->
                      def unzip_dir = path.toString()  // Ensure path is a string
                      def barcode = unzip_dir.tokenize('/').last()  // Extract the directory name
                      [barcode, unzip_dir]  // Return a list containing the directory name and path
    }}

	// CONCATENATE FQS PER SAMPLE
	concat_fastqs(unzipped_fq_dirs)
	
	// PORECHOP NANOPORE ADAPTERS 
	porechop(concat_fastqs.out.concat_fq)

  // SCREEN FOR CONTAMINANTS 
	kraken2(porechop.out.trimmed_fq, kraken2_db)

  // ASSEMBLE GENOME WITH FLYE
	flye_assembly(porechop.out.trimmed_fq)

  // ASSEMBLE GENOME WITH UNICYCLER
	unicycler_assembly(porechop.out.trimmed_fq)

  // CLUSTER CONTIGS WITH TRYCYCLER 
  combined_assemblies = unicycler_assembly.out.unicycler_assembly
                .join(flye_assembly.out.flye_assembly, by:0)
                .join(porechop.out.trimmed_fq, by:0)
                .map { barcode, unicycler_assembly, flye_assembly, trimmed_fq ->
                  tuple(barcode, unicycler_assembly, flye_assembly, trimmed_fq)}
                
  trycycler_cluster(combined_assemblies)

  // CLASSIFY CONTIGS WITH TRYCYCLER
  classify_trycycler(trycycler_cluster.out.trycycler_cluster)

  // RECONCILE CONTIGS WITH TRYCYCLER
  contigs_to_reconcile = classify_trycycler.out.reconcile_contigs
                      .join(porechop.out.trimmed_fq, by: 0)
                      .flatMap { barcode, reconcile_contigs, trimmed_fq ->
                        if (reconcile_contigs instanceof List) {
                          reconcile_contigs.collect { cluster_dir ->
                            tuple(barcode, cluster_dir, trimmed_fq)
                          }
                        } else {
                          [tuple(barcode, reconcile_contigs, trimmed_fq)]
                        }
                      }

  trycycler_reconcile(contigs_to_reconcile)

  // SELECT WHETHER CONSENSUS OR FLYE ASSEMBLY IS BEST QUALITY
  select_in = trycycler_reconcile.out.reconciled_seqs
              .groupTuple(by:[0])
              .join(flye_assembly.out.flye_assembly, by:0)
              .join(kraken2.out.kraken2_screen, by:0)
              .map { barcode, reconciled, flye_assembly, k2_report ->
                  tuple(barcode, reconciled, flye_assembly, k2_report)}

  select_assembly(select_in, get_ncbi.out.ncbi_lookup)	

  // IF CONSENSUS ASSEMBLY IS BEST...
  
  //RUN MULTIPLE SEQUENCE ALIGNMENT
  msa_in = select_assembly.out.consensus_good
          .filter { it[1].exists() }
          .map {barcode, consensus_good->
            tuple(barcode, consensus_good)} 

  trycycler_msa(msa_in)

  // PARTITION READS 
  partition_in = select_assembly.out.consensus_good
                .filter { it[1].exists() }
                .join(porechop.out.trimmed_fq, by: 0)
                .map {barcode, consensus_good, trimmed_fq->
                  tuple(barcode, consensus_good, trimmed_fq)} 
  
  trycycler_partition(partition_in)

  // BUILD CONSENSUS ASSEMBLY 
  consensus_in = select_assembly.out.consensus_good
                .join(trycycler_msa.out.three_msa, by: 0)
                .join(trycycler_partition.out.four_reads, by:0)
                .map { barcode, consensus_good, three_msa, four_reads ->
                  tuple(barcode, consensus_good, three_msa, four_reads)}

  trycycler_consensus(consensus_in)

  // POLISH CONSENSUS ASSEMBLY
  consensus_polish_in = trycycler_partition.out.four_reads
                        .join(trycycler_consensus.out.consensus_consensus, by:0)
                        .map { barcode, four_reads, consensus_consensus ->
                          tuple(barcode, four_reads, consensus_consensus)}  

  medaka_polish_consensus(consensus_polish_in)

  // IF CONSENSUS FAILS, WE REVERT TO FLYE ASSEMBLY AS NEXT BEST THING...
  // TODO refine this, probably more complicated than it needs to be
  good_barcodes = select_assembly.out.consensus_good
                  .map { barcode, consensus_good -> barcode }
                  .collect()

  filtered_discard = select_assembly.out.consensus_discard
                    .map { barcode, consensus_discard -> barcode }
                    .filter { barcode -> !good_barcodes.get().contains(barcode) }

  flye_polish_in = filtered_discard
                  .join(flye_assembly.out.flye_assembly, by: 0)
                  .join(porechop.out.trimmed_fq, by: 0)
                  .map { barcode, flye_assembly, trimmed_fq -> tuple(barcode, flye_assembly, trimmed_fq) }
                  
  medaka_polish_flye(flye_polish_in)

  // DETECT PLASMIDS AND OTHER MOBILE ELEMENTS 
  plassembler_in = porechop.out.trimmed_fq
                  .join(flye_assembly.out.flye_assembly, by: 0)
                  .map { barcode, trimmed_fq, flye_assembly -> tuple(barcode, trimmed_fq, flye_assembly) }
                  
  plassembler(plassembler_in, get_plassembler.out.plassembler_db)

  // ANNOTATE PLASMID FEATURES (BUSCO)
  busco_plasmids_in = plassembler.out.plasmids

  //busco_annotation_plasmids()

  // ANNOTATE CHROMOSOME FEATURES (BUSCO)

  // ANNOTATE PLASMID FEATURES (BATKA)
  
  // ANNOTATE CHROMOSOME FEATURES (BAKTA)  

  // ANNOTATE VIRULENCE GENES 

  // ANNOTATE AMR GENES 

  // CONSTRUCT PHYLOGENETIC TREE

  // SUMMARISE RUN WITH MULTIQC REPORT

}

// Print workflow execution summary 
workflow.onComplete {
summary = """
=======================================================================================
Workflow execution summary
=======================================================================================

Duration    : ${workflow.duration}
Success     : ${workflow.success}
workDir     : ${workflow.workDir}
Exit status : ${workflow.exitStatus}
results     : ${params.outDir}

=======================================================================================
  """
println summary

}
