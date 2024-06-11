process pycoqc_summary {
   tag "EVALUATING RAW READ QC: ${params.input}"
  container 'quay.io/biocontainers/pycoqc:2.5.2--py_0'

  input:
  path(params.input)

  output:
  path("*"), emit: pycoqc_summary

  script: 
  """
  # THIS ISNT FUNCTIONAL
  pycoQC \\
    -f ${params.input}/sequencing_summary*.txt \\
    -o results/pycoQC_output.html
  """
}
