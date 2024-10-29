process medaka_polish_denovo {
  tag "${assembler_name}: ${barcode}"
  container 'quay.io/biocontainers/medaka:1.11.3--py39h05d5c5e_0'
  publishDir "${params.outdir}/assemblies/${barcode}_${assembler_name}", mode: 'symlink'

  input:
  tuple val(barcode), val(assembler_name), path(assembly), path(trimmed_fq)

  output:
  tuple val(barcode), val(assembler_name), path("medaka/consensus.fasta"), emit: assembly

  script:
  """
  # ideally the assembly file is passed in directly
  medaka_consensus \\
    -i ${trimmed_fq} \\
    -d ${assembly}/assembly.fasta \\
    -t ${task.cpus}
  """
}
