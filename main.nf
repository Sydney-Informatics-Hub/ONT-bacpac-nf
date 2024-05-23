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
include { processOne } from './modules/process1'
include { processTwo } from './modules/process2' 

// Print a header for your pipeline 
log.info """\

=======================================================================================
Name of the pipeline - nf 
=======================================================================================

Created by <YOUR NAME> 
Find documentation @ https://sydney-informatics-hub.github.io/Nextflow_DSL2_template_guide/
Cite this pipeline @ INSERT DOI

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
  Usage:  nextflow run main.nf --input <samples.tsv> 

  Required Arguments:

  --input		Specify full path and name of sample input file.

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
	
	// DEFINE CHANNELS 
	// See https://www.nextflow.io/docs/latest/channel.html#channels
	// See https://training.nextflow.io/basic_training/channels/ 

	// VALIDATE INPUT SAMPLES 
	check_input(Channel.fromPath(params.input, checkIfExists: true))

	// PROCESS 1
	// See https://training.nextflow.io/basic_training/processes/#inputs 
	processOne(check_input.out.samplesheet)
	
	// PROCESS 2 USING OUTPUT OF PROCESS 1 
	processTwo(processOne.out.File)
}}

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
