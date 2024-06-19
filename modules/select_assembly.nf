process check_consensus {
  tag "SELECTING THE BEST ASSEMBLY: ${barcode}"  
  container 'depot.galaxyproject.org/singularity/python:3.8.3'

  input:
  tuple val(barcode), path(assemblies)
  path(k2_report)

    - kraken2 taxanomy report: modules/run_kraken2.nf 
    - Output folder from flye assembly: modules/run_flye.nf
    - sample_id+"_cluster": the trycluster cluster folder carried forward from classify_trycycler_clusters.py 

  output:
  tuple val(barcode), path("${barcode}_discarded/*"), emit: discard_contigs
  tuple val(barcode), path("${barcode}_for_reconciliation/*"), emit: reconcile_contigs

  script: 
  """
  select_assembly.py \\
    ${barcode} 
  """
}