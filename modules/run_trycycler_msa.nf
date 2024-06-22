process trycycler_msa {
  tag "MULTI SEQUENCE ALIGNMENT FOR SUCCESSFUL TRYCYCLER ASSEMBLY: ${barcode}"
  container 'quay.io/biocontainers/trycycler:0.5.4--pyhdfd78af_0'

  input:
  tuple val(barcode), path(consensus_final), path(consensus_fail)

  when:
  consensus_final.exists()

  script:
  """
  trycycler msa \\
    --cluster_dir ${barcode}_final/cluster* \\
    --threads ${task.cpus}
  
  # Move the 3_msa.fasta to a new directory 
  #mv 
  """
}
