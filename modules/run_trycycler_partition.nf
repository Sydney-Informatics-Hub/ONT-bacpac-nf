process trycycler_partition {
  tag "PARTITIONING READS: ${barcode}"
  container 'quay.io/biocontainers/trycycler:0.5.4--pyhdfd78af_0'

  input:
  tuple val(barcode), path(consensus_file), path(consensus_good), path(trimmed_fq)

  //when:
  //consensus_good.exists()
  
  output: 
  tuple val(barcode), path("${barcode}_partitioned"), emit: four_reads

  script: 
  """ 
  # Capture path to reconciled directory
  reconciled_dir=\$(find -L . -type d -name 'cluster_*_reconciled')
  echo \$reconciled_dir

  echo $consensus_good

  # Run trycycler partition step: https://github.com/rrwick/Trycycler/wiki/Partitioning-reads
  trycycler partition \\
    --reads ${barcode}_trimmed.fastq.gz \\
    --cluster_dirs \$reconciled_dir

  # Move files to out directory
  mkdir -p ${barcode}_partitioned
  for dir in \$reconciled_dir; do
    mkdir -p ${barcode}_partitioned/\${dir}
    cp \${dir}/2_all_seqs.fasta ${barcode}_partitioned/\${dir}/2_all_seqs.fasta
    cp \${dir}/4_reads.fastq ${barcode}_partitioned/\${dir}/4_reads.fastq
  
  done
  """

}
