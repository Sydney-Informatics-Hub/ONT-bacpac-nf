process nanoplot_summary {
  tag "SUMMARISING RAW OUTPUT FROM ONT RUN: ${sequencing_summary.fileName}"
  container 'quay.io/biocontainers/nanoplot:1.42.0--pyhdfd78af_0'
  publishDir "${params.outdir}/quality_control", mode: 'copy'
  
  input:
  tuple val(batch), path(sequencing_summary)

  output:
  tuple val(batch), path("nanoplot_summary.${batch}"), emit: nanoplot_summary

  script: 
  """
  NanoPlot \\
    --summary ${sequencing_summary} \\
    --loglength \\
    -o nanoplot_summary.${batch} \\
    -p ${batch}
  """
}

