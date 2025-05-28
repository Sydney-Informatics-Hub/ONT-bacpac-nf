process generate_bandage_report {
  tag "GENERATE BANDAGE REPORT"
  // container 'quay.io/biocontainers/bandage:0.9.0--h9948957_0'
  publishDir "${params.outdir}/report/bandage", mode: 'copy'

  input:
  path bandage_plots, stageAs: 'figures/*'

  output:
  path "bandage_mqc.html", emit: bandage_report

  script:
  """
  generate_bandage_report.py --templatedir $params.bandage_templates figures/*.svg
  """
}
