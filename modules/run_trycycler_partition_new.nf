process trycycler_partition_new {
  tag "PARTITIONING READS: ${barcode}"
  container 'quay.io/biocontainers/trycycler:0.5.4--pyhdfd78af_0'

  input:
  tuple val(barcode), path(cluster_dirs), path(trimmed_fq)

  output: 
  tuple val(barcode), path("**/4_reads.fastq"), emit: partitioned_reads

  script: 
  """ 
  trycycler partition \\
    --reads $trimmed_fq \\
    --cluster_dirs $cluster_dirs \\
    --threads ${task.cpus}
  """

}
