process porechop {
  //TODO see comment in ../bin/inputchecker.py to speed up unzipping and concatenating into 2 processes step 1: 1 per cohort, step 2: 1 per sample
  tag "TRIMMING ADAPTERS: ${barcode}"
  container 'quay.io/biocontainers/porechop:0.2.4--py39h1f90b4d_6'

  input:
	tuple val(barcode), path(concat_fq)
    
  output:
  path '*' , emit: trimmed_fq

  script: 
  """
  porechop --input ${concat_fq} \\
    --threads ${task.cpus} \\
    --output ${barcode}_trimmed.fastq.gz
    """
}