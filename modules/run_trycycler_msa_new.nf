process trycycler_msa_new {
  tag "ALIGNING RECONCILED TRYCYCLER SEQS: ${barcode}: ${cluster_dir}"
  container 'quay.io/biocontainers/trycycler:0.5.4--pyhdfd78af_0'

  input:
  tuple val(barcode), path(cluster_dir)	

  output:
  tuple val(barcode), path("${cluster_dir}/"), emit: results_dir
  tuple val(barcode), path("${cluster_dir}/3_msa.fasta"), emit: aligned_seqs

  script:
  """
  trycycler msa \\
    --cluster_dir $cluster_dir \\
    --threads ${task.cpus}
  """
}
