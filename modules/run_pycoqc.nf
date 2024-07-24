process pycoqc_summary {
  tag "SUMMARISING RAW OUTPUT FROM ONT RUN: ${params.input}"
  container 'quay.io/biocontainers/pycoqc:2.5.2--py_0'
  publishDir "${params.outdir}/quality_control", mode: 'symlink'

  input:
  path(sequencing_summary_file_path)

  output:
  path("pycoqc_summary.html"), emit: pycoqc_summary

  script: 
  """
  # THIS ISNT FUNCTIONAL
  pycoQC \\
    -f ${sequencing_summary_file_path}/sequencing_summary*.txt \\
    -o pycoqc_summary.html
  """
}
