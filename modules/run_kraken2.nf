process kraken2 {
  tag "DETECTING POSSIBLE CONTAMINATION: ${barcode}"

  input:
  tuple val(barcode), path(trimmed_fq)
  path(kraken2_db)

  output:
  tuple val(barcode), path("*"), emit: kraken2_screen

  script: 
  """
  kraken2 \\
    --db ${kraken2_db} \\
    --report ${barcode}/${barcode}.k2report \\
    --report-minimizer-data \\
    --minimum-hit-groups 3 ${trimmed_fq} \\
    --threads ${task.cpus} \\
    --output ${barcode}/${barcode}_k2_out.txt 
  """
}
