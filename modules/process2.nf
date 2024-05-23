// Define the process
process processTwo {
	// Define directives 
	// See: https://nextflow.io/docs/edge/process.html#processes
	debug = true //turn to false to stop printing command stdout to screen
	tag "WOKRING ON: ${params.input}" 
	publishDir "${params.outdir}/processTwo", mode: 'copy'
  container '' 

	// Define input 
	// See: https://www.nextflow.io/docs/latest/process.html#inputs
	input:
	file("process1out.txt")

	// Define output(s)
	// See: https://www.nextflow.io/docs/latest/process.html#outputs
	output:
	path("process2out.txt")

	// Define code to execute 
	// See: https://www.nextflow.io/docs/latest/process.html#script
	script:
	"""
    tac processed_cohort.txt | rev \
    	> process2out.txt
	"""
 }