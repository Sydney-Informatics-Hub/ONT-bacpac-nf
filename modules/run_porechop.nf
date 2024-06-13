process porechop {
  tag "TRIMMING ADAPTERS: ${barcode}"
  container 'quay.io/biocontainers/porechop:0.2.4--py39h1f90b4d_6'

  input:
	tuple val(barcode), path(concat_fq)
    
  output:
	tuple val(barcode),  path("*") , emit: trimmed_fq

  script: 
  """
  porechop --input ${concat_fq} \\
    --threads ${task.cpus} \\
    --output ${barcode}_trimmed.fastq.gz
    """
}