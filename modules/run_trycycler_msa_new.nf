process trycycler_msa_new {
  tag "MSA FOR SUCCESSFUL TRYCYCLER ASSEMBLY: ${barcode}"
  container 'quay.io/biocontainers/trycycler:0.5.4--pyhdfd78af_0'

  input:
  tuple val(barcode), path(reconciled_dir)	

  output:
  tuple val(barcode), val("${barcode}_${reconciled_dir}"), path("${barcode}_${reconciled_dir}_msa"), emit: three_msa

  script:
  """
  # Run trycycler MSA step: https://github.com/rrwick/Trycycler/wiki/Multiple-sequence-alignment
  trycycler msa \\
    --cluster_dir ${reconciled_dir} \\
    --threads ${task.cpus}
  
  # Move the 3_msa.fasta to out directory
  mkdir -p ${barcode}_${reconciled_dir}_msa
  cp ${reconciled_dir}/3_msa.fasta ${barcode}_${reconciled_dir}_msa/3_msa.fasta  
  """
}
