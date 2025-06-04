process autocycler_table_mqc {
  tag "AUTOCYCLER TABLE MQC PREP: ${barcode}"
  container 'quay.io/biocontainers/pandas:2.2.1'
  publishDir "${params.outdir}/report/autocycler", mode: 'copy'

  input:
  tuple val(barcode), path(metrics_tsv)

  output:
  tuple val(barcode), path("autocycler_mqc.tsv"), emit: metrics

  script:
  """
  generate_autocycler_metrics_mqc.py -i ${metrics_tsv} -o autocycler_mqc.tsv
  """
}
