process pycoqc_summary {
   tag "EVALUATING RAW READ QC: ${barcode}"

  input:
  tuple val(barcode), path(trimmed_fq)

  output:
  tuple val(barcode), path("*"), emit: kraken2_screen

  script: 
  """
  # THIS ISNT FUNCTIONAL
  pycoQC \\
    -f raw_data/sequencing_summary*.txt \\
    -o results/pycoQC_output.html
  """
}
