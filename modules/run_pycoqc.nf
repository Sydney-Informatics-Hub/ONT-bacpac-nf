process pycoqc_summary {
  tag "SUMMARISING RAW OUTPUT FROM ONT RUN: ${file.sequencing_summary}"
  container 'quay.io/biocontainers/pycoqc:2.5.2--py_0'
  publishDir "${params.outdir}/quality_control", mode: 'symlink'

  input:
  path(sequencing_summary)

  output:
  path("pycoqc_summary.html"), emit: pycoqc_summary

  script: 
  """
  pycoQC \\
    -f ${params.sequencing_summary} \\
    -o pycoqc_summary.html
  """
}
