process check_input {
  //TODO see comment in ../bin/inputchecker.py to speed up unzipping and concatenating into 2 processes step 1: 1 per cohort, step 2: 1 per sample
  tag "VALIDATING INPUT DIRECTORY: ${input.fileName}"
  container 'depot.galaxyproject.org/singularity/python:3.8.3'

  input:
	path input
    
  output:
  path 'unzipped_inputs/*' , emit: unzipped

  script: // This process runs ../bin/inputchecker.py 
  """
	inputchecker.py \\
    $input \\
    unzipped_inputs
  """
}