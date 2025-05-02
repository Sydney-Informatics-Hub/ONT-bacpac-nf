process classify_trycycler {
  tag "CLASSIFYING CONTIGS: ${barcode}"  
  container 'python:3.8'

  input:
  tuple val(barcode), path(trycycler_cluster), val(num_contigs)

  output:
  tuple val(barcode), path("${barcode}_discarded/*"), emit: clusters_to_discard, optional: true
  tuple val(barcode), path("${barcode}_for_reconciliation/*"), emit: clusters_to_reconcile

  script:
  n_assemblers = 2 * params.subsamples
  """
  classify_trycycler_clusters.py ${barcode} ${n_assemblers}
  """
}
