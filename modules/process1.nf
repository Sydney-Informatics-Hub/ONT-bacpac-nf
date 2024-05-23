// Define the process
process processOne {	
	// Define directives 
	// See: https://nextflow.io/docs/edge/process.html#processes
	debug = true //turn to false to stop printing command stdout to screen
	tag "WORKING ON: ${params.input}" 
	publishDir "${params.outdir}/processOne", mode: 'symlink'
  container '' 

	// Define input 
	// See: https://www.nextflow.io/docs/latest/process.html#inputs
	input:
	val input

	// Define output(s)
	// See: https://www.nextflow.io/docs/latest/process.html#outputs
	output:
	path ("process1out.txt"), emit: File
	
	// Define code to execute 
	// See: https://www.nextflow.io/docs/latest/process.html#script
	script:
	"""
	echo $params.input | tr '[a-z]' '[A-Z]' \
		> process1out.txt
	"""
}