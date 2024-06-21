process select_assembly {
  tag "SELECTING THE BEST ASSEMBLY: ${barcode}"  
  container 'depot.galaxyproject.org/singularity/python:3.8.3'

  input:
  tuple val(barcode), path(reconciled), path(flye_assembly), path(kraken2_report)
  path(ncbi_lookup)

  output:
  tuple val(barcode), path("*"), emit: best_assembly

  script: 
  """
  select_assembly.py \\
    ${barcode} \\
    ${reconciled} \\
    ${flye_assembly} \\
    ${kraken2_report} \\
    ${ncbi_lookup}
  """
}