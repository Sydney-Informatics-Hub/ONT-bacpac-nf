process estimate_genome_size_raven {
  tag "ESTIMATE GENOME SIZE: ${barcode}"
  container 'quay.io/biocontainers/raven-assembler:1.8.3--h5ca1c30_3'

  input:
  tuple val(barcode), path(trimmed_fq)

  output:
  tuple val(barcode), path("raven.fasta"), emit: raven_fa

  script:
  """
  raven --threads ${task.cpus} --disable-checkpoints ${trimmed_fq} > raven.fasta
  """
}

process estimate_genome_size_seqtk {
  tag "ESTIMATE GENOME SIZE: ${barcode}"
  container 'quay.io/biocontainers/seqtk:1.4--h577a1d6_3'

  input:
  tuple val(barcode), path(raven_fa)

  output:
  tuple val(barcode), path("${barcode}_genome_size.txt"), emit: genome_size

  script:
  """
  seqtk size ${raven_fa} | cut -f 2 > ${barcode}_genome_size.txt
  """
}

workflow estimate_genome_size {
  take:
  trimmed_fq

  main:
  estimate_genome_size_raven(trimmed_fq)
  estimate_genome_size_seqtk(estimate_genome_size_raven.out.raven_fa)

  emit:
  genome_size = estimate_genome_size_seqtk.out.genome_size
}