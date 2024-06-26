process trycycler_partition {
  tag "PARTITIONING READS: ${barcode}"
  container 'quay.io/biocontainers/trycycler:0.5.4--pyhdfd78af_0'

  input:
  tuple val(barcode), path(consensus_good), path(trimmed_fq)

  output: 
  
   
  script: 
  """ 
  # Capture path to reconciled directory
  reconciled_dir=\$(ls -d */* | grep 'barcode01_final/cluster_[0-9]*_reconciled')
  echo \$reconciled_dir

  # Run trycycler partition step: https://github.com/rrwick/Trycycler/wiki/Partitioning-reads
  trycycler partition \\
    --reads ${barcode}_trimmed.fastq.gz \\
    --cluster_dirs \$reconciled_dir

  # Move 4_reads.fastq to out directory
  mkdir -p ${barcode}_partitioned
  mv \${reconciled_dir}/4_reads.fastq ${barcode}_partitioned/4_reads.fastq
  """
}