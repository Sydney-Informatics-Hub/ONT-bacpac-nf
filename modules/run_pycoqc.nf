process pycoqc_summary {
  tag "SUMMARISING RAW OUTPUT FROM ONT RUN: ${sequencing_summary.fileName}"
  container 'quay.io/biocontainers/pycoqc:2.5.2--py_0'
  publishDir "${params.outdir}/quality_control", mode: 'copy'

  input:
  tuple val(batch), path(sequencing_summary)

  output:
  tuple val(batch), path("${batch}.html"), emit: pycoqc_html
  tuple val(batch), path("${batch}.json"), emit: pycoqc_json
  
  script: 
  """
  pycoQC \\
    -f ${sequencing_summary} \\
    -o ${batch}.html \\
    -j ${batch}.json
  """
}
