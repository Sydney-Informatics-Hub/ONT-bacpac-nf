process trycycler_reconcile {
  tag "RECONCILING CONTIGS: ${barcode}: ${cluster_dir}"
  container 'quay.io/biocontainers/trycycler:0.5.4--pyhdfd78af_0'

  input:
  tuple val(barcode), path(cluster_dir), path(trimmed_fq)

  output: 
  tuple val(barcode), path("${cluster_dir}/"), emit: results_dir
  tuple val(barcode), path("${cluster_dir}/2_all_seqs.fasta"), emit: reconciled_seqs, optional: true 
  /* 
   * optional:true as reconcililation may be unsuccessful (true negative) 
   * i.e. if there is too much of a length difference between contigs in the 
   * one cluster
   */

  script: 
  """
  trycycler reconcile \\
      --reads $trimmed_fq \\
      --cluster_dir $cluster_dir \\
      --threads ${task.cpus} \\
      --min_1kbp_identity 10 \\
      --max_add_seq 2500
  """
}
