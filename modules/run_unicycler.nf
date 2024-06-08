process unicycler_assembly {
  tag "ASSEMBLING GENOME: ${barcode}"

  input:
  tuple val(barcode), path(trimmed_fq)
  path(kraken2_db)

  output:
  tuple val(barcode), path("*"), emit: unicycler_assembly

  script: 
  """
  unicycler \
    --long ${trimmed_fq} \
    --threads ${task.cpus} \
  """
}
