process estimate_genome_size {
  tag "ESTIMATE GENOME SIZE: ${barcode}"
  container 'quay.io/biocontainers/raven-assembler:1.8.3--h5ca1c30_3'

  // errorStrategy { task.exitStatus == 1 ? 'ignore' : 'terminate' } 

  input:
  tuple val(barcode), path(trimmed_fq)

  output:
  tuple val(barcode), path("${barcode}_genome_size.txt"), emit: genome_size

  script:
  """
  genome_size_raven.sh ${trimmed_fq} ${task.cpus} > "${barcode}_genome_size.txt"
  """
}
