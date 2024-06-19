process classify_trycycler {
  tag "CLASSIFYING CONTIGS: ${barcode}"  
  container 'depot.galaxyproject.org/singularity/python:3.8.3'

  input:
  tuple val(barcode), path(trycycler_cluster)

  output:
  tuple val(barcode), path("${barcode}_discarded/*"), emit: discard_contigs
  tuple val(barcode), path("${barcode}_for_reconciliation/*"), emit: reconcile_contigs

  script: 
  """
  classify_trycycler_clusters.py \\
    ${barcode} 
  """
}