process nanoplot_summary {
  tag "SUMMARISING INPUT: ${params.input}"
  container 'quay.io/biocontainers/nanoplot:1.42.0--pyhdfd78af_0'

  input:
	path input

  output:
  path("*"), emit: nanoplot_summary

  script: 
  """
  # THIS ISNT FUNCTIONAL
  NanoPlot \\
    --summary ${params.input}/sequencing_summary*.txt \\
    --loglength \\
    -o nanoplot_summary_plots
  """
}

