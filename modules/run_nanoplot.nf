process nanoplot_summary {
  tag "SUMMARISING RAW OUTPUT FROM ONT RUN: ${params.input}"
  container 'quay.io/biocontainers/nanoplot:1.42.0--pyhdfd78af_0'
  publishDir "${params.outdir}/raw_qc", mode: 'symlink'
  
  input:
  path(sequencing_summary_file_path)

  output:
  path("*"), emit: nanoplot_summary

  script: 
  """
  NanoPlot \\
    --summary ${sequencing_summary_file_path}/sequencing_summary*.txt \\
    --loglength \\
    -o nanoplot_summary_plots
  """
}

