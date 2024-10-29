process medaka_polish_consensus_new {
  tag "${barcode}: ${cluster_dir}"
  container 'quay.io/biocontainers/medaka:1.11.3--py39h05d5c5e_0'
  publishDir "${params.outdir}/assemblies/${barcode}_consensus", mode: 'symlink'

  input:
  tuple val(barcode), path(cluster_dir)

  output:
  tuple val(barcode), path("consensus.fasta"), emit: cluster_assembly

  script:
  """
  medaka_consensus \\
    -i ${cluster_dir}/4_reads.fastq \\
    -d ${cluster_dir}/7_final_consensus.fasta \\
    -o ./ \\
    -t ${task.cpus}
  """
}
