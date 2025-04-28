#!/usr/bin/env nextflow

// To use DSL-2 will need to include this
nextflow.enable.dsl=2

// Import processes or subworkflows to be run in the workflow
include { check_input } from './modules/check_input'
include { check_samplesheet } from './modules/check_samplesheet'
include { concat_fastas } from './modules/concat_fa'
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
include { estimate_genome_size } from './modules/run_estimate_genome_size'
include { flye_assembly } from './modules/run_flye'
include { flye_assembly_subset } from './modules/run_flye_subset'
include { unicycler_assembly } from './modules/run_unicycler'
include { unicycler_assembly_subset } from './modules/run_unicycler_subset'
include { autocycler_subsample } from './modules/run_autocycler_subsample'
include { trycycler_cluster } from './modules/run_trycycler_cluster'
include { trycycler_cluster_subset } from './modules/run_trycycler_cluster_subset'
include { classify_trycycler } from './modules/run_trycycler_classify'
include { trycycler_reconcile } from './modules/run_trycycler_reconcile'
include { select_assembly } from './modules/select_assembly'
include { trycycler_msa } from './modules/run_trycycler_msa'
include { trycycler_partition } from './modules/run_trycycler_partition'
include { trycycler_consensus} from './modules/run_trycycler_consensus'
include { medaka_polish_denovo } from './modules/run_medaka_polish_denovo'
include { medaka_polish_consensus } from './modules/run_medaka_polish_consensus'
include { plassembler } from './modules/run_plassembler'
include { bakta_annotation_plasmids } from './modules/run_bakta_annotation_plasmids'
include { busco_annotation_plasmids } from './modules/run_busco_annotation_plasmids'
include { quast_qc_chromosomes } from './modules/run_quast_qc_chromosomes'
include { bakta_annotation_chromosomes } from './modules/run_bakta_annotation_chromosomes'
include { busco_qc_chromosomes } from './modules/run_busco_qc_chromosomes'
include { abricateVFDB_annotation_chromosomes } from './modules/run_abricateVFDB_annotation_chromosomes'
include { abricateVFDB_annotation_reference } from './modules/run_abricateVFDB_annotation_reference'
include { amrfinderplus_annotation_chromosomes } from './modules/run_amrfinderplus_annotation_chromosomes'
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

	
""".stripIndent()
}

// Define workflow structure. Include some input/runtime tests here.
// See https://www.nextflow.io/docs/latest/dsl2.html?highlight=workflow#workflow
workflow {

if ( params.help || (!params.input_directory && !params.samplesheet)) {   
// Invoke the help function above and exit
	helpMessage()
	System.exit(1)
	// consider adding some extra contigencies here.
	// could validate path of all input files in list?
	// could validate indexes for reference exist?

// If none of the above are a problem, then run the workflow
} else {
  get_busco()
  busco_db = get_busco.out.busco_db

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

  // CONCATENATE FQS PER SAMPLE
  concat_fastqs(unzipped_fq_dirs)
  
  // PORECHOP NANOPORE ADAPTERS 
  porechop(concat_fastqs.out.concat_fq)

  // ESTIMATE GENOME SIZE
  estimate_genome_size(porechop.out.trimmed_fq)

  autocycler_inputs = porechop.out.trimmed_fq
    .join(estimate_genome_size.out.genome_size, by:0)

  // SUBSAMPLE FASTQ FILES
  autocycler_subsample(autocycler_inputs)

  // Expand the multiple FASTQs per barcode to one tuple per subset
  subsets = autocycler_subsample.out.subsets.transpose()

  subsets.view()

  // DE NOVO GENOME ASSEMBLIES
  // flye_assembly_subset(subsets)
  // unicycler_assembly_subset(subsets)

  /*
   * CONSENSUS ASSEMBLY PRE-PROCESSING
   * 
   * Trycycler requires >= 3 contigs to run. Use the in-built .countFasta()
   * operator to count the total number of contigs assembled for each barcode.
   *
   * If additional assemblers/read subsets/replicates are added, ensure it 
   * is added here.
   */
  /*
  num_contigs_per_barcode =
    unicycler_assembly_subset.out.unicycler_assembly
    .mix(flye_assembly_subset.out.flye_assembly)
    .map { barcode, assembly_dir ->
        // Count num contigs per assembly
        def fa = assembly_dir + "/assembly.fasta"
        def ncontigs = fa.countFasta()
        return [barcode, ncontigs]
    }
    .groupTuple()
    .map { barcode, ncontigs ->
        // Add total contigs across assemblies
        def total_contigs = ncontigs.inject(0, { result, x -> result + x.toInteger() })
        return [barcode, total_contigs]
    }

  unicycler_assembly_subset_grouped = unicycler_assembly_subset.out.unicycler_assembly
    .groupTuple()
  flye_assembly_subset_grouped = flye_assembly_subset.out.flye_assembly
    .groupTuple()
  denovo_assemblies =
    unicycler_assembly_subset_grouped
    .join(flye_assembly_subset_grouped, by:0)
    .join(porechop.out.trimmed_fq, by:0)
    .join(num_contigs_per_barcode, by:0)

  denovo_assembly_contigs =
    denovo_assemblies
    .branch { barcode, unicycler, flye, trimmed_fq, num_contigs ->
        run_trycycler: num_contigs >= 3
        skip_trycycler: num_contigs < 3
    }

  // RUN TRYCYCLER (CONSENSUS ASSEMBLY) IF SUFFICIENT # CONTIGS
  // TRYCYCLER: Cluster contigs
  trycycler_cluster_subset(denovo_assembly_contigs.run_trycycler)

  barcode_cluster_sizes =
    // trycycler_cluster filters out small contigs (default < 5000nt) and can
    // result in < 2 contigs here again. Use the same branching logic to avoid
    // < 2 contig errors.
    trycycler_cluster_subset.out.phylip
    .map { barcode, contigs_phylip ->
        def phylip_lines = contigs_phylip.text.readLines().size - 1 // exclude header
        return [barcode, phylip_lines]
    }
    .branch { barcode, phylip_lines ->
        run_trycycler: phylip_lines >= 3
        skip_trycycler: phylip_lines < 3
        // create a channel from skip_trycycler if failed barcodes need to be reported/used
    }

  // TRYCYCLER: Classify clusters
  clusters_to_classify =
    // Add path to clusters with sufficient contigs
    trycycler_cluster_subset.out.clusters
    .join(barcode_cluster_sizes.run_trycycler)

  classify_trycycler(clusters_to_classify)

  // TRYCYCLER: Reconcile contigs
  clusters_to_reconcile_flat = 
    classify_trycycler.out.clusters_to_reconcile
    .join(porechop.out.trimmed_fq, by: 0)
    // from [barcode, [pathA, pathB], ...]
    // to [barcode, pathA, ...]; [barcode, pathB, ...]
    .transpose()

  trycycler_reconcile(clusters_to_reconcile_flat)

  reconciled_cluster_dirs = 
    trycycler_reconcile.out.reconciled_seqs // successfully reconciled
    .map { barcode, seq ->
        // drops the last part of the path (reconciled_seqs file) as trycycler
        // searches the parent dir for it
        Path cluster_dir = seq.getParent()
        return [barcode, cluster_dir] 
    }
  
  // TRYCYCLER: Align
  trycycler_msa(reconciled_cluster_dirs)

  // TRYCYCLER: Partitioning reads
  clusters_to_partition =
    trycycler_msa.out.results_dir
    .groupTuple()
    .join(porechop.out.trimmed_fq)

  trycycler_partition(clusters_to_partition)

  // TRYCYCLER: Generate consensus assemblies  
  clusters_for_consensus =
    trycycler_partition.out.partitioned_reads
    .transpose() // "ungroup" tuple
    .map { barcode, reads ->
        // Get directories of successfully partitioned reads
        Path cluster_dir = reads.getParent()
        return [barcode, cluster_dir]
    }

  trycycler_consensus(clusters_for_consensus)

  // MEDAKA: Polish consensus assembly
  consensus_dir = 
    // Get parent dir for assembly
    trycycler_consensus.out.cluster_assembly
    .map { barcode, assembly ->
        Path assembly_dir = assembly.getParent()
        return [barcode, assembly_dir]
    }

  medaka_polish_consensus(consensus_dir)

  // CAT: Combine polished clusters consensus assemblies into a single fasta
  polished_clusters = 
    medaka_polish_consensus.out.cluster_assembly
    .groupTuple()
    .map { barcode, fastas ->
        // Need to avoid filename collisions with consensus.fasta files
        // by renaming them
        def indexed_fas = 
            fastas.withIndex()
            .collect { fa, idx ->
                def new_fa = fa.getParent() / "consensus_${idx}.fasta"
                fa.copyTo(new_fa)
                return new_fa
            }
        return [barcode, indexed_fas]
    }
  
  concat_fastas(polished_clusters)

  polished_consensus_per_barcode = concat_fastas.out

  // MEDAKA: POLISH DE NOVO ASSEMBLIES
  // Doesn't yet handle the subset assemblies
  // unpolished_denovo_assemblies =
  //   unicycler_assembly_subset.out.unicycler_assembly
  //   .mix(flye_assembly_subset.out.flye_assembly)
  //   .map { barcode, assembly_dir -> 
  //       // Get the assembler name by parsing the publishDir path.
  //       // A better way to do this is output i.e. val(assembler_name) in the
  //       // assembly processes but will required more changes
  //       String assembler_name = assembly_dir.toString().tokenize("_")[-2]
  //       return [barcode, assembler_name, assembly_dir] 
  //   }
  //   .combine(porechop.out.trimmed_fq, by: 0)

  // medaka_polish_denovo(unpolished_denovo_assemblies)

  // ASSEMBLY QC
  all_polished =
    polished_consensus_per_barcode
    .map { barcode, consensus_fa ->
        // technically should be "trycycler" but want to separate it out from
        // the denovo assemblies clearly
        String assembler = "consensus"
        return [barcode, assembler, consensus_fa]
    }
    // .mix(medaka_polish_denovo.out.assembly)

  // TODO: probably better to collect all per-barcode assemblies in one quast
  // run to void a parsing/merging step
  quast_qc_chromosomes(all_polished)
  busco_qc_chromosomes(all_polished, get_busco.out.busco_db)
  */
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
