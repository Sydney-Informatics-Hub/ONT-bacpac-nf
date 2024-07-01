process flye_assembly {
  tag "ASSEMBLING GENOME: ${barcode}"
  container 'quay.io/biocontainers/flye:2.9.3--py310h2b6aa90_0'
  //publishDir "${params.outDir}", mode: 'symlink'

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
