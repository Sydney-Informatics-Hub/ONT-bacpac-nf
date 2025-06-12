process autocycler_table_mqc {
  tag "AUTOCYCLER TABLE MQC PREP: ${barcode}"
  container 'quay.io/biocontainers/pandas:2.2.1'
  publishDir "${params.outdir}/report/autocycler", mode: 'copy'

  input:
  path(metrics_tsvs)

  output:
  path("autocycler_mqc.tsv"), emit: metrics

  script:
  """
  generate_autocycler_metrics_mqc.py -o autocycler_mqc.tsv ${metrics_tsvs}
  """
}
