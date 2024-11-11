process pycoqc_summary {
  tag "SUMMARISING RAW OUTPUT FROM ONT RUN: ${sequencing_summary.fileName}"
  container 'quay.io/biocontainers/pycoqc:2.5.2--py_0'
  publishDir "${params.outdir}/quality_control", mode: 'copy'

  input:
  path(sequencing_summary)

  output:
  path("pycoqc_summary.html"), emit: pycoqc_html
  path("pycoqc_summary.json"), emit: pycoqc_json
  
  script: 
  """
  pycoQC \\
    -f ${params.sequencing_summary} \\
    -o pycoqc_summary.html \\
    -j pycoqc_summary.json
  """
}
