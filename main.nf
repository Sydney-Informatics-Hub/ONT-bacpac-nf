#!/usr/bin/env nextflow

/// To use DSL-2 will need to include this
nextflow.enable.dsl=2

// =================================================================
// main.nf is the pipeline script for a nextflow pipeline
// Should contain the following sections:
	// Process definitions
    // Channel definitions
    // Workflow structure
	// Workflow summary logs 

// Examples are included for each section. Remove them and replace
// with project-specific code. For more information see:
// https://www.nextflow.io/docs/latest/index.html.
//
// ===================================================================

// Import processes or subworkflows to be run in the workflow
// Each of these is a separate .nf script saved in modules/ directory
// See https://training.nextflow.io/basic_training/modules/#importing-modules 
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
//include { trycycler_cluster } from './modules/run_trycycler_cluster'
//include { trycycler_classify } from './modules/run_trycycler_classify'
//include { trycycler_reconcile } from './modules/run_trycycler_reconcile'
//include { check_consensus } from './modules/check_trycycler'
//include { trycycler_msa } from './modules/run_trycycler_msa'
//include { trycycler_partition } from './modules/run_trycycler_partition'
//include { trycycler_consensus} from './modules/run_trycycler_consensus'
//include { medaka_polish_consensus } from './modules/run_medaka_polish_consensus'
//include { medaka_polish_flye } from './modules/run_medaka_polish_flye'
//include { plassembler } from './modules/run_plassembler'
//include { busco_annotation_plasmids } from './modules/run_busco_annotation_plasmids'
//include { busco_annotation_chromosomes } from './modules/run_busco_annotation_chromosome'
//include { bakta_annotation_plasmids } from './modules/run_bakta_annotation_plasmids'
//include { bakta_annotation_chromosomes } from './modules/run_bakta_annotation_chromosomes'
//include { abricate_amr_virulence } from './modules/run_abricate_amr_virulence'
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
      log.info "Using existing kraken db ${params.kraken2_db}"
      kraken2_db = params.kraken2_db
    }

    // Only download bakta if existing db not already provided 
    if (!params.bakta_db){
      get_bakta()

    } else { 
      log.info "Using existing kraken db ${params.bakta_db}"
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
    //.view()

	// CONCATENATE FQS PER SAMPLE
	concat_fastqs(unzipped_fq_dirs)
	
	// PORECHOP NANOPORE ADAPTERS 
	porechop(concat_fastqs.out.concat_fq)
  //.view()
  
  // SCREEN FOR CONTAMINANTS 
  // TODO THIS CURRENTLY DOESN'T FUNCTION
	kraken2(porechop.out.trimmed_fq, kraken2_db)

  // ASSEMBLE GENOME WITH FLYE
  // TODO THIS CURRENTLY DOESN'T FUNCTION
	flye_assembly(porechop.out.trimmed_fq)

  // ASSEMBLE GENOME WITH UNICYCLER
  // TODO THIS CURRENTLY DOESN'T FUNCTION
	unicycler_assembly(porechop.out.trimmed_fq)

  // 
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
