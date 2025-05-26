process bandage {
  tag "BANDAGE: ${barcode} - ${assembly}"
  container 'quay.io/biocontainers/bandage:0.9.0--h9948957_0'
  publishDir "${params.outdir}/assemblies/${barcode}_${assembly}", mode: 'copy'

  input:
  tuple val(barcode), val(assembly), path(gfa_file)

  output:
  tuple val(barcode), val(assembly), path("${barcode}.${assembly}.assembly.svg"), emit: bandage_plot

  script:
  """
  Bandage image ${gfa_file} ${barcode}.${assembly}.assembly.svg
  """
}
