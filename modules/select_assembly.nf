process select_assembly {
  tag "EVALUATING CONSENSUS ASSEMBLY QUALITY: ${barcode}"  
  container 'depot.galaxyproject.org/singularity/python:3.8.3'

  input:
  tuple val(barcode), path(reconciled), path(flye_assembly), path(kraken2_report)
  path(ncbi_lookup)

  output:
  tuple val(barcode), path("Consensus.txt"), path("${barcode}_final/*"), emit: consensus_good, optional: true
  tuple val(barcode), path("FlyeOnly.txt"), path("${barcode}_flye_assembly/Chr_contigs/"), emit: consensus_discard, optional: true

  script: 
  //TODO double check this is capturing all reconciled clusters
  """
  select_assembly.py \\
    ${barcode} \\
    ${reconciled.join(' ')} \\
    ${flye_assembly} \\
    ${kraken2_report} \\
    ${ncbi_lookup}
  """
}
