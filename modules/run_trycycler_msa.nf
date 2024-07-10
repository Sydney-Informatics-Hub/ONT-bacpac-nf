process trycycler_msa {
  tag "MULTI SEQUENCE ALIGNMENT FOR SUCCESSFUL TRYCYCLER ASSEMBLY: ${barcode}"
  container 'quay.io/biocontainers/trycycler:0.5.4--pyhdfd78af_0'

  input:
  //tuple val(barcode), path(consensus_file), path(consensus_good)
  tuple val(barcode), path(consensus_file), path(reconciled_dir)	

  //when:
  //consensus_good.exists()

  output:
  // TODO fix this output to capture stdout and msa fasta separately
  tuple val(barcode), path("cluster_*_reconciled/3_msa.fasta"), emit: three_msa

  script:
  """
  # Capture path to reconciled directory
  #reconciled_dir=\$(ls -d */* | grep 'barcode01_final/cluster_[0-9]*_reconciled')
  #echo \$reconciled_dir

  # Run trycycler MSA step: https://github.com/rrwick/Trycycler/wiki/Multiple-sequence-alignment
  trycycler msa \\
    --cluster_dir $reconciled_dir \\
    --threads ${task.cpus}
  
  # Move the 3_msa.fasta to out directory
  #mkdir -p ${barcode}_msa
  #mv ${reconciled_dir}/3_msa.fasta ${barcode}_msa/3_msa.fasta
  """
}
