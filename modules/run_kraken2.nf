process kraken2 {
  tag "DETECTING POSSIBLE CONTAMINATION: ${barcode}"
  container 'quay.io/biocontainers/kraken2:2.1.3--pl5321hdcf5f25_0'

  input:
  tuple val(barcode), path(trimmed_fq)
  path kraken2_db 

  //output:
  //tuple val(barcode), path("*"), emit: kraken2_screen

  script:
  """
  kraken2 ${trimmed_fq} \\
    --db ${kraken2_db} \\
    --report ${barcode}/${barcode}.k2report \\
    --report-minimizer-data \\
    --minimum-hit-groups 3 \\
    --threads ${task.cpus} \\
    --output ${barcode}/${barcode}_k2_out.txt 
  """
}
