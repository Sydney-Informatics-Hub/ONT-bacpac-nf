process trycycler_reconcile_new {
  tag "RECONCILING CONTIGS: ${barcode}: ${reconcile_contigs}"
  container 'quay.io/biocontainers/trycycler:0.5.4--pyhdfd78af_0'

  input:
  tuple val(barcode), path(reconcile_contigs), path(trimmed_fq)

  output: 
  tuple val(barcode), path("${reconcile_contigs}/"), emit: results, optional: true 
  tuple val(barcode), path("${reconcile_contigs}/*/2_all_seqs.fasta"), emit: all_seqs, optional: true 
  /* 
   * optional:true as reconcililation may be unsuccessful (true negative) 
   * i.e. if there is too much of a length difference between contigs in the 
   * one cluster
   */

  script: 
  """
  trycycler reconcile \\
      --reads ${trimmed_fq} \\
      --cluster_dir ${reconcile_contigs} \\
      --threads ${task.cpus} \\
      --min_1kbp_identity 10 \\
      --max_add_seq 2500
  """
}
