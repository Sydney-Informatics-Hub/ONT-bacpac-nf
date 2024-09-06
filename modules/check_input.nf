process check_input {
  //TODO see comment in ../bin/inputchecker.py to speed up unzipping and concatenating into 2 processes step 1: 1 per cohort, step 2: 1 per sample
  tag "VALIDATING INPUT DIRECTORY: ${input.fileName}"
  container 'python:3.8'

  input:
	path input_directory
    
  output:
  path 'unzipped_fqs/*' , emit: unzipped

  script: // This process runs ../bin/inputchecker.py 
  """
	inputchecker.py \\
    $input_directory \\
    unzipped_fqs
  """
}
