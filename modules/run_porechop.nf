process porechop {
  tag "TRIMMING ADAPTERS FROM RAW READS: ${sample}"
  container 'quay.io/biocontainers/porechop:0.2.4--py39h1f90b4d_6'

  input:
	tuple val(sample), path(concat_fq)
    
  output:
	tuple val(sample),  path("*") , emit: trimmed_fq

  script: 
  """
  porechop --input ${concat_fq} \\
    --threads ${task.cpus} \\
    --output ${sample}_trimmed.fastq.gz
  """
}