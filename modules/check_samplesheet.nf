process check_samplesheet {
  //TODO see comment in ../bin/inputchecker.py to speed up unzipping and concatenating into 2 processes step 1: 1 per cohort, step 2: 1 per sample
  tag "VALIDATING INPUT SAMPLESHEET: ${samplesheet.fileName}"
  container 'python:3.8'

  input:
	path samplesheet
    
  output:
  path 'unzipped_fqs/*' , emit: unzipped

  script: // This process runs ../bin/samplesheet_checker.py 
  """
	samplesheet_checker.py \\
    $samplesheet \\
    unzipped_fqs
  """
}
