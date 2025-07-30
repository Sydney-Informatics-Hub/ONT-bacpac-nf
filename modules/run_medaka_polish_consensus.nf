process medaka_polish_consensus {
  tag "${barcode}: ${cluster_dir}"
  container 'quay.io/biocontainers/medaka:1.11.3--py39h05d5c5e_0'
  publishDir "${params.outdir}/assemblies/${barcode}_consensus", mode: 'copy'

  input:
  tuple val(barcode), path(fastq), path(fasta)

  output:
  tuple val(barcode), path("consensus.fasta"), emit: polished_assembly

  script:
  cluster_dir = fasta.getParent()
  """
  medaka_consensus \\
    -i ${fastq} \\
    -d ${fasta} \\
    -o ./ \\
    -t ${task.cpus}
  """
}
