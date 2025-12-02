process medaka_polish_consensus {
  tag "${sample}: ${cluster_dir}"
  container 'quay.io/biocontainers/medaka:1.11.3--py39h05d5c5e_0'
  publishDir "${params.outdir}/assemblies/${sample}_consensus", mode: 'copy'

  input:
  tuple val(sample), path(fastq), path(fasta)

  output:
  tuple val(sample), path("consensus.fasta"), emit: polished_assembly

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
