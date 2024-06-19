process classify_trycycler {
  tag "CLUSTERING CONTIGS: ${barcode}"  
  container 'depot.galaxyproject.org/singularity/python:3.8.3'

  input:
  tuple val(barcode), path(trycycler_cluster)

  output:
  tuple val(barcode), path("*"), emit: classified_contigs

  script: 
  """
  classify_trycycler_clusters.py \\
    ${barcode} 
  """
}