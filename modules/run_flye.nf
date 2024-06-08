process flye_assembly {
  tag "ASSEMBLING GENOME: ${barcode}"

  input:
  tuple val(barcode), path(trimmed_fq)

  output:
  tuple val(barcode), path("*"), emit: flye_assembly

  script: 
  """
  flye \\
    --nano-hq ${trimmed_fq} \\
    --threads ${task.cpus} \\
    --out-dir ${barcode}_flye_assembly
  """
}
