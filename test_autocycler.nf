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
include { estimate_genome_size } from './subworkflows/estimate_genome_size'
include { flye_assembly } from './modules/run_flye'
include { flye_assembly_subset } from './modules/run_flye_subset'
include { unicycler_assembly } from './modules/run_unicycler'
include { unicycler_assembly_subset } from './modules/run_unicycler_subset'
include { autocycler_subsample } from './modules/run_autocycler_subsample'
include { autocycler_compress } from './modules/run_autocycler_compress'
include { autocycler_cluster } from './modules/run_autocycler_cluster'
include { autocycler_trim } from './modules/run_autocycler_trim'
include { autocycler_resolve } from './modules/run_autocycler_resolve'
include { autocycler_combine } from './modules/run_autocycler_combine'
include { autocycler_table } from './modules/run_autocycler_table'
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

  // DE NOVO GENOME ASSEMBLIES
  flye_assembly_subset(subsets)
  unicycler_assembly_subset(subsets)

  all_assembly_dirs = flye_assembly_subset.out.flye_assembly
    .mix(unicycler_assembly_subset.out.unicycler_assembly)
    .groupTuple(by:0)

  autocycler_compress(all_assembly_dirs)

  autocycler_cluster(autocycler_compress.out.compressed)

  clusters_for_refinement = autocycler_cluster.out.pass_clusters
    .transpose()
    .map { barcode, cluster_dir ->
      cluster_id = cluster_dir.baseName
      return [ barcode, cluster_id, cluster_dir ]
    }

  autocycler_trim(clusters_for_refinement)

  autocycler_resolve(autocycler_trim.out.trimmed_cluster)

  autocycler_resolve_out = autocycler_resolve.out.resolved_cluster
    .groupTuple(by:0)

  autocycler_combine_inputs = autocycler_cluster.out.cluster_out
    .join(autocycler_resolve_out, by:0)
    .map { barcode, autocycler_cluster_dir, cluster_ids, pass_cluster_dirs ->
      [ barcode, autocycler_cluster_dir, pass_cluster_dirs ]
    }

  autocycler_combine(autocycler_combine_inputs)

  autocycler_table(autocycler_combine.out.autocycler_out)

  // ASSEMBLY QC
  consensus =
    autocycler_combine.out.autocycler_out
    .map { barcode, autocycler_dir ->
        String assembler = "autocycler"
        def consensus_fa = autocycler_dir / "consensus_assembly.fasta"
        return [barcode, assembler, consensus_fa]
    }

  quast_qc_chromosomes(consensus)
  busco_qc_chromosomes(consensus, get_busco.out.busco_db)
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
