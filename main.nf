#!/usr/bin/env nextflow

// To use DSL-2 will need to include this
nextflow.enable.dsl=2

// Import processes or subworkflows to be run in the workflow
include { check_input } from './modules/check_input'
include { check_samplesheet } from './modules/check_samplesheet'
include { concat_fastqs } from './modules/run_pigz'
include { porechop } from './modules/run_porechop' 
include { pycoqc_summary } from './modules/run_pycoqc'
include { nanoplot_summary } from './modules/run_nanoplot'
include { get_ncbi } from './modules/get_ncbi'
include { get_busco } from './modules/get_busco'
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
include { bakta_annotation_plasmids } from './modules/run_bakta_annotation_plasmids'
include { busco_annotation_plasmids } from './modules/run_busco_annotation_plasmids'
include { quast_qc_chromosomes } from './modules/run_quast_qc_chromosomes'
include { quast_qc_flye_chromosomes } from './modules/run_quast_qc_flye_chromosomes'
include { bakta_annotation_chromosomes } from './modules/run_bakta_annotation_chromosomes'
include { bakta_annotation_flye_chromosomes } from './modules/run_bakta_annotation_flye_chromosomes'
include { busco_annotation_chromosomes } from './modules/run_busco_annotation_chromosomes'
include { busco_annotation_flye_chromosomes } from './modules/run_busco_annotation_flye_chromosomes'
include { abricateVFDB_annotation_chromosomes } from './modules/run_abricateVFDB_annotation_chromosomes'
include { abricateVFDB_annotation_flye_chromosomes } from './modules/run_abricateVFDB_annotation_flye_chromosomes'
include { abricateVFDB_annotation_reference } from './modules/run_abricateVFDB_annotation_reference'
include { amrfinderplus_annotation_chromosomes } from './modules/run_amrfinderplus_annotation_chromosomes'
include { amrfinderplus_annotation_flye_chromosomes } from './modules/run_amrfinderplus_annotation_flye_chromosomes'
include { create_samplesheet_for_processed } from './modules/create_samplesheet_for_processed'
include { create_phylogeny_tree_related_files } from './modules/create_phylogeny_tree_related_files'
include { run_orthofinder } from './modules/run_orthofinder'
include { amrfinderplus_annotation_reference } from './modules/run_amrfinderplus_annotation_reference'
include { generate_amrfinderplus_gene_matrix } from './modules/generate_amrfinderplus_gene_matrix'
include { generate_abricate_gene_matrix } from './modules/generate_abricate_gene_matrix'
include { create_phylogeny_And_Heatmap_image } from './modules/create_phylogeny_And_Heatmap_image'
include { multiqc_report } from './modules/run_multiqc'

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
inputDir           : ${params.input_directory} 
samplesheet        : ${params.samplesheet}
sequencing_summary : ${params.sequencing_summary}
results            : ${params.outdir}
workDir            : ${workflow.workDir}
profiles           : ${workflow.profile}
=======================================================================================

"""

/// Help function 
// This is an example of how to set out the help function that 
// will be run if run command is incorrect or missing. 

def helpMessage() {
    log.info"""
  Usage:  nextflow run main.nf --input_directory <path to directory> 

  Required Arguments:

  --input_directory   Specify full path and name of directory OR
  --samplesheet       Spectify full path and name of samplesheet csv. 

  Optional Arguments:

  --outdir              Specify path to output directory.
  --multiqc_config      Configure multiqc reports.
  --sequencing_summary	Sequencing summary log from sequencer.
	
""".stripIndent()
}

// Define workflow structure. Include some input/runtime tests here.
// See https://www.nextflow.io/docs/latest/dsl2.html?highlight=workflow#workflow
workflow {

if ( params.help || (!params.input_directory && !params.samplesheet) || !params.sequencing_summary) {   
// Invoke the help function above and exit
	helpMessage()
	System.exit(1)
	// consider adding some extra contigencies here.
	// could validate path of all input files in list?
	// could validate indexes for reference exist?

// If none of the above are a problem, then run the workflow
} else {

  // DOWNLOAD DATABASES  
  get_amrfinderplus()
  amrfinderplus_db = get_amrfinderplus.out.amrfinderplus_db

  get_plassembler()
  plassembler_db = get_plassembler.out.plassembler_db

  get_ncbi()
  //TODO revise the requirement for this process. We'll need the lookup for the tree, but likely not for select_assembly 

  get_busco()
  busco_db = get_busco.out.busco_db
  
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
  if (params.input_directory){
      log.info "USING INPUT DIRECTORY ${params.input_directory}"
    	  check_input(params.input_directory)
  
  	// READ SUBDIRECTORIES FROM UNZIPPED_INPUTS
	      unzipped_fq_dirs = check_input.out.unzipped
          .flatten()
          .map { path ->
          def unzip_dir = path.toString()  // Ensure path is a string
          def barcode = unzip_dir.tokenize('/').last()  // Extract the directory name
          [barcode, unzip_dir]}  // Return a list containing the directory name and path

  } else { 
      log.info "FYI USING SAMPLESHEET ${params.samplesheet}"
    	  check_samplesheet(params.samplesheet)
        
        unzipped_fq_dirs = check_samplesheet.out.unzipped
          .flatten()
          .map { path ->
          def unzip_dir = path.toString()  // Ensure path is a string
          def barcode = unzip_dir.tokenize('/').last()  // Extract the directory name
          [barcode, unzip_dir]}  // Return a list containing the directory name and path

    }}

  // PREPARE INPUTS

  // QC SUMMARY OF RAW INPUTS 
  // INPUT FILE GENERATED BY THE ONT MACHINE 
  sequencing_summary = params.sequencing_summary

  nanoplot_summary(sequencing_summary)
  pycoqc_summary(sequencing_summary)

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

  // DETECT PLASMIDS AND OTHER MOBILE ELEMENTS 
  plassembler_in = porechop.out.trimmed_fq
                  .join(flye_assembly.out.flye_assembly, by: 0)
                  .map { barcode, trimmed_fq, flye_assembly -> tuple(barcode, trimmed_fq, flye_assembly) }
                  
  plassembler(plassembler_in, get_plassembler.out.plassembler_db)

  // CLUSTER CONTIGS WITH TRYCYCLER 
  combined_assemblies = unicycler_assembly.out.unicycler_assembly
                .join(flye_assembly.out.flye_assembly, by:0)
                .join(porechop.out.trimmed_fq, by:0)
                .map { barcode, unicycler_assembly, flye_assembly, trimmed_fq ->
                  tuple(barcode, unicycler_assembly, flye_assembly, trimmed_fq)}

  trycycler_cluster(combined_assemblies)

  /* 
   * Building a tree requires >2 contigs.
   * Use `contigs.phylip` to check the number of contigs. The number of lines
   * in a `.phylip` indicates the number of contigs/tips.
   */ 
  assemblies_with_trycycler_clusters = trycycler_cluster.out.trycycler_cluster 
    .map { barcode, assemblies, cluster_phylip ->
        def phylip_lines = cluster_phylip.text.readLines().size() - 1 // Exclude header
        return [barcode, assemblies, phylip_lines] 
    }
    .branch { barcode, assemblies, phylip_lines ->
        run_trycycler: phylip_lines >= 3 // Enough clusters/contigs
        skip_trycycler: phylip_lines < 3
    }

  trycycler_skipped_barcodes =
    // barcodes with insufficient contigs for trycycler
    assemblies_with_trycycler_clusters.skip_trycycler
    .map { barcode, assemblies, phylip_lines -> barcode }
    .collect()

  // RUN TRYCYCLER (CONSENSUS ASSEMBLY) IF SUFFICIENT # CONTIGS
  // CLASSIFY CONTIGS WITH TRYCYCLER
  classify_trycycler(assemblies_with_trycycler_clusters.run_trycycler)

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

  /*
   * SELECT "BEST" ASSEMBLY (CONSENSUS (TRYCYCLER) OR FLYE)
   *    TODO: Revise reference-free approach 
   *    TODO: Include unicycler assembly too
   */
  trycycler_reconciled = 
    // Channel for successful trycycler assemblies
    trycycler_reconcile.out.reconciled_seqs
    .groupTuple(by:[0])
  
  select_in = trycycler_reconcile.out.reconciled_seqs
              .groupTuple(by:[0])
              .join(flye_assembly.out.flye_assembly, by:0)
              .join(kraken2.out.kraken2_screen, by:0)
              .map { barcode, reconciled, flye_assembly, k2_report ->
                  tuple(barcode, reconciled, flye_assembly, k2_report)}

  select_assembly(select_in, get_ncbi.out.ncbi_lookup)	

  // IF CONSENSUS ASSEMBLY IS BEST...

  // TRYCYCLER MULTIPLE SEQUENCE ALIGNMENT
  // CONSENSUS APPROACH : Check if file Consensus.txt exists
  msa_in_consensus = select_assembly.out.consensus_good
          .filter { it[1].exists() }  // Ensure the correct path is checked for existence
          .flatMap { tuple ->
            def barcode = tuple[0]
            def consensus_file = tuple[1]
            def final_path = tuple[2]
            if (final_path instanceof List) {
                // If final_path is a list, return a stream of separate tuples
                final_path.collect { path ->
                    [barcode, consensus_file, path]
                }
            } else {
                // If final_path is not a list, return a single-element list with the original tuple
                [[barcode, consensus_file, final_path]]
            }
          }
          
  trycycler_msa(msa_in_consensus)
  trycycler_msa_out = trycycler_msa.out.three_msa

  // TRYCYCLER PARTITIONING READS
  partition_in = select_assembly.out.consensus_good
          .filter { it[1].exists() }  // Ensure the correct path is checked for existence
          .join(porechop.out.trimmed_fq, by: 0)
  	  .map { barcode, consensus_file, final_path, trimmed_fq ->
            tuple(barcode, consensus_file, final_path, trimmed_fq)
          }

  trycycler_partition(partition_in)

  // TRYCYCLER CONSENSUS
  partition_out_raw = trycycler_partition.out.four_reads

  partition_out = partition_out_raw.flatMap { barcode, path ->
    def directory = new File(path.toString())
    def files = directory.listFiles().findAll { it.name.endsWith('_reconciled') }
    files.collect { file -> [barcode, "${barcode}_${file.name}", file.path] }
  }

// TODO MAKE NAMING CONSISTENT WITH OTHER CHANNELS
  consensus_in = trycycler_msa_out
  		 .join(partition_out, by:1)
                 .map { row ->
                     [row[1], row[0], row[2], row[4]]
                 }

  trycycler_consensus(consensus_in)

  // MEDAKA POLISH CONSENSUS ASSEMBLY
  // TODO MAKE NAMING CONSISTENT WITH OTHER CHANNELS
  consensus_polish_in = partition_out
                        .join(trycycler_consensus.out.consensus_consensus, by:1)
			                  .map { row ->[row[1], row[0], row[2], row[4]]}

  medaka_polish_consensus(consensus_polish_in)

  // ANNOTATE VARIOUS CONSENSUS-CHROMOSOME FEATURES  
  // TODO MAKE NAMING CONSISTENT WITH OTHER CHANNELS
  polish_grouped_by_barcode = medaka_polish_consensus.out.consensus_polished
			.groupTuple(by:[0])
			.map { row -> [row[0], row[2]]}

  // QUAST QC CONSENSUS-ASSEMBLY
  quast_qc_chromosomes(polish_grouped_by_barcode)

  // BAKTA ANNOTATE GENE FEATURES 
  bakta_annotation_chromosomes(polish_grouped_by_barcode,get_bakta.out.bakta_db)

  // BUSCO ANNOTATE CONSENSUS-CHROMOSOME FEATURES
  busco_annotation_chromosomes(bakta_annotation_chromosomes.out.bakta_annotations, get_busco.out.busco_db) 

  // AMRFINDERPLUS ANNOTATE CONSENSUS-CHROMOSOME AMR-GENES
  amrfinderplus_annotation_chromosomes(bakta_annotation_chromosomes.out.bakta_annotations,
                                        get_amrfinderplus.out.amrfinderplus_db)
  
  // ABRICATE ANNOTATE CONSENSUS-CHROMOSOME WITH VFDB-GENES
  abricateVFDB_annotation_chromosomes(polish_grouped_by_barcode)

  consensus_processed_samples=amrfinderplus_annotation_chromosomes.out.map { it[0] }.collect()

  // IF FLYE ASSEMBLY IS BEST...

  /*
   * Channel that has the ids for all samples that either:
   *  1. Has too few contigs for trycycler/consensus assembly
   *  2. Enough contigs but flye > consensus assembly
   *
   * flye_better_barcode channel emits each sample id separately for joining
   * with the paths to the flye assembly and trimmed fqs later
   * 
   */
  flye_better_barcodes = select_assembly.out.consensus_discard
    .map { barcode, consensus_file, filtered_flye_contigs -> barcode }
    .mix(trycycler_skipped_barcodes)
    .flatMap()

  /*
   * MEDAKA-POLISH FLYE ASSEMBLY 
   *
   * The current select_assembly process discards any non-chromosomal
   * contigs based on a reference-based NCBI lookup.
   *
   * The following channel passes in ALL contigs assembled by flye for
   * polishing as select_assembly is revised. i.e. not just the putatively
   * chromosmal ones.
   *
   */
  flye_polish_in =
    flye_better_barcodes
    .join(flye_assembly.out.flye_assembly, by: 0)
    .join(porechop.out.trimmed_fq, by: 0)

  medaka_polish_flye(flye_polish_in)

  // QUAST QC FLYE-ONLY ASSEMBLY 
  quast_qc_flye_chromosomes(medaka_polish_flye.out.flye_polished)

  // BAKTA ANNOTATE FLYE-ONLY CHROMOSOME FEATURES 
  bakta_annotation_flye_chromosomes(medaka_polish_flye.out.flye_polished,get_bakta.out.bakta_db)

  // BUSCO ANNOTATE FLYE-ONLY-CHROMOSOME FEATURES
  busco_annotation_flye_chromosomes(bakta_annotation_flye_chromosomes.out.bakta_annotations, get_busco.out.busco_db)

  // AMRFINDERPLUS ANNOTATE FLYE-ONLY AMR-GENES
  amrfinderplus_annotation_flye_chromosomes(bakta_annotation_flye_chromosomes.out.bakta_annotations,
                                            get_amrfinderplus.out.amrfinderplus_db)

  flye_only_processed_samples=amrfinderplus_annotation_flye_chromosomes.out
                              .map { it[0] }.collect()

  // ABRICATE ANNOTATE FLYE-CHROMOSOME WITH VFDB-GENES
  abricateVFDB_annotation_flye_chromosomes(medaka_polish_flye.out.flye_polished)
  
  kraken_input_to_create_phylogeny_tree = kraken2.out
                                            .map { [it[1]] }
	                                          .collect()

  consensus_bakta=bakta_annotation_chromosomes.out.bakta_annotations
                  .map { [it[1]] }.collect()

  flye_only_bakta=bakta_annotation_flye_chromosomes.out.bakta_annotations
                  .map { [it[1]] }.collect()

// CREATE FILES FOR PHYLOGENETIC TREE BUILDING
// Check if flye_only_bakta is empty, and use only consensus_bakta if it is
all_bakta_input_to_create_phylogeny_tree = flye_only_bakta
    .ifEmpty([]) // If flye_only_bakta is empty, provide an empty list
    .merge(consensus_bakta) // Merge with consensus_bakta
    //.view()

create_phylogeny_tree_related_files(
    get_ncbi.out.assembly_summary_refseq,
    kraken_input_to_create_phylogeny_tree,
    all_bakta_input_to_create_phylogeny_tree
)

  // ORTHOFINDER PHYLOGENETIC ORTHOLOGY INFERENCE
  run_orthofinder(create_phylogeny_tree_related_files.out.phylogeny_folder)


  // AMRIFINDER ANNOTATE REFERENCE STRAINS FOR AMR GENES
  amrfinderplus_annotation_reference(create_phylogeny_tree_related_files.out.phylogeny_folder,
                                    get_amrfinderplus.out.amrfinderplus_db)

  // ABRICATE ANNOTATE REFERENCE STRAINS FOR AMR GENES
  abricateVFDB_annotation_reference(create_phylogeny_tree_related_files.out.phylogeny_folder) 

  // GENERATE AMRFINDERPLUS gene matrix (FOR PHYLOGENY-AMR HEATMAP) 
  consensus_amrfinderplus_output=amrfinderplus_annotation_chromosomes.out
                                  .map { it[1] }
                                  .collect()

  flye_only_amrfinderplus_output=amrfinderplus_annotation_flye_chromosomes.out
                                  .map { it[1] }
                                  .collect()

// Check if flye_only_amrfinderplus_output is empty, and use only consensus_amrfinderplus_output if it is
  all_samples_amrfinderplus_output = flye_only_amrfinderplus_output
    .ifEmpty([]) // If flye_only_amrfinderplus_output is empty, provide an empty list
    .merge(consensus_amrfinderplus_output) // Merge with consensus_amrfinderplus_output

  all_references_amrfinderplus_output = amrfinderplus_annotation_reference.out.amrfinderplus_annotations
  
  barcode_species_table = create_phylogeny_tree_related_files.out.barcode_species_table

  generate_amrfinderplus_gene_matrix(all_samples_amrfinderplus_output,
                                      all_references_amrfinderplus_output,
                                      barcode_species_table)

  // GENERATE ABRICATE-VFDB gene matrix (FOR PHYLOGENY-AMR HEATMAP)
  consensus_abricate_output=abricateVFDB_annotation_chromosomes.out
                            .map { it[1] }
                            .collect()

  flye_only_abricate_output=abricateVFDB_annotation_flye_chromosomes.out
                            .map { it[1] }
                            .collect()

//  all_samples_abricate_output = consensus_abricate_output
//                                .merge(flye_only_abricate_output)

// Check if flye_only_abricate_output is empty, and use only consensus_abricate_output if it is
all_samples_abricate_output = flye_only_abricate_output
    .ifEmpty([]) // If flye_only_abricate_output is empty, provide an empty list
    .merge(consensus_abricate_output) // Merge with consensus_abricate_output

  all_references_abricate_output = abricateVFDB_annotation_reference.out.abricate_annotations

  generate_abricate_gene_matrix(all_samples_abricate_output,
                                all_references_abricate_output,
                                barcode_species_table)

  // CREATE PHYLOGENETIC TREE + HEATMAP IMAGE
  create_phylogeny_And_Heatmap_image(run_orthofinder.out.phylogeny_tree,
                                    generate_amrfinderplus_gene_matrix.out.amrfinderplus_gene_matrix,
                                    generate_abricate_gene_matrix.out.abricate_gene_matrix)

  // ANNOTATE PLASMID FEATURES (BATKA)
  bakta_annotation_plasmids(plassembler.out.plassembler_fasta, get_bakta.out.bakta_db)

  // SUMMARISE RUN WITH MULTIQC REPORT
  // Ensure all necessary inputs are available for MultiQC, even if some are empty
  nanoplot_required_for_multiqc = nanoplot_summary.out.nanoplot_summary.ifEmpty([])
  pycoqc_required_for_multiqc = pycoqc_summary.out.pycoqc_json.ifEmpty([])

kraken2_required_for_multiqc = kraken2.out.kraken2_screen
    .map { it[1] }
    .collect()
    .ifEmpty([])

quast_required_for_multiqc = quast_qc_chromosomes.out.quast_qc_multiqc
    .map { it[1] }
    .collect()
    .merge(
        quast_qc_flye_chromosomes.out.quast_qc_multiqc
        .map { it[1] }
        .collect()
        .ifEmpty([])
    )

bakta_required_for_multiqc = bakta_annotation_chromosomes.out.bakta_annotations_multiqc
    .map { it[1] }
    .collect()
    .merge(
        bakta_annotation_flye_chromosomes.out.bakta_annotations_multiqc
        .map { it[1] }
        .collect()
        .ifEmpty([])
    )

busco_required_for_multiqc = busco_annotation_chromosomes.out.busco_annotations
    .map { it[1] }
    .collect()
    .merge(
        busco_annotation_flye_chromosomes.out.busco_annotations
        .map { it[1] }
        .collect()
        .ifEmpty([])
    )

bakta_plasmids_required_for_multiqc = bakta_annotation_plasmids.out.bakta_annotations
    .map { it[1] }
    .collect()
    .ifEmpty([])

phylogeny_heatmap_plot_required_for_multiqc = create_phylogeny_And_Heatmap_image.out.combined_plot_mqc
    .ifEmpty([])

multiqc_config = params.multiqc_config

// Run MultiQC with the gathered inputs
multiqc_report(
    pycoqc_required_for_multiqc,
    nanoplot_required_for_multiqc,
    multiqc_config,
    kraken2_required_for_multiqc,
    quast_required_for_multiqc,
    bakta_required_for_multiqc,
    bakta_plasmids_required_for_multiqc,
    busco_required_for_multiqc,
    phylogeny_heatmap_plot_required_for_multiqc
)
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
results     : ${params.outdir}

=======================================================================================
  """
println summary

}
