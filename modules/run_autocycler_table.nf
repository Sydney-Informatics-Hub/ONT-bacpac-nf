process autocycler_table {
  tag "AUTOCYCLER TABLE: ${barcode}"
  container 'quay.io/biocontainers/autocycler:0.3.0--h3ab6199_0'
  publishDir "${params.outdir}/assemblies/${barcode}_consensus", mode: 'copy'

  input:
  tuple val(barcode), path(autocycler_dir)

  output:
  tuple val(barcode), path("metrics.tsv"), emit: metrics

  script:
  """
  autocycler table > metrics.tsv  # Header row
  autocycler table \\
    --autocycler_dir autocycler_out \\
    --name ${barcode} \\
    >> metrics.tsv
  """
}
