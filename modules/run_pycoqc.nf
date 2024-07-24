process pycoqc_summary {
  tag "EVALUATING RAW READ QC: ${params.input}"
  container 'quay.io/biocontainers/pycoqc:2.5.2--py_0'
  publishDir "${params.outdir}/raw_qc", mode: 'symlink'
  
  input:
  path(sequencing_summary_file_path)

  output:
  path("pycoQC_output.html"), emit: pycoqc_summary

  script: 
  """
  # THIS ISNT FUNCTIONAL
  pycoQC \\
    -f ${sequencing_summary_file_path}/sequencing_summary*.txt \\
    -o pycoQC_output.html
  """
}
