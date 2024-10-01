process classify_trycycler {
  tag "CLASSIFYING CONTIGS: ${barcode}"  
  container 'python:3.8'

  input:
  tuple val(barcode), path(trycycler_cluster), val(num_contigs)

  output:
  tuple val(barcode), path("${barcode}_discarded/*"), emit: discard_contigs, optional: true
  tuple val(barcode), path("${barcode}_for_reconciliation/*"), emit: reconcile_contigs

  script: 
  """
  classify_trycycler_clusters.py \\
    ${barcode} 
  """
}
