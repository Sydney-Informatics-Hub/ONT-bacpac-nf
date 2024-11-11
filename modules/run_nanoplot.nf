process nanoplot_summary {
  tag "SUMMARISING RAW OUTPUT FROM ONT RUN: ${sequencing_summary.fileName}"
  container 'quay.io/biocontainers/nanoplot:1.42.0--pyhdfd78af_0'
  publishDir "${params.outdir}/quality_control", mode: 'copy'
  
  input:
  path(sequencing_summary)

  output:
  path("*"), emit: nanoplot_summary

  script: 
  """
  NanoPlot \\
    --summary ${params.sequencing_summary} \\
    --loglength \\
    -o nanoplot_summary
  """
}

