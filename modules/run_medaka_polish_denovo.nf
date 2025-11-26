process medaka_polish_denovo {
  tag "${assembler_name}: ${barcode}"
  container 'quay.io/biocontainers/medaka:1.11.3--py39h05d5c5e_0'
  publishDir "${params.outdir}/assemblies/${barcode}_${assembler_name}", mode: 'copy'

  input:
  tuple val(barcode), val(assembler_name), path(assembly), path(trimmed_fq)

  output:
  tuple val(barcode), val(assembler_name), path("consensus.fasta"), emit: assembly

  script:
  fa_path = assembler_name == 'plassembler' ? "${assembly}/plassembler_plasmids.fasta" : "${assembly}/assembly.fasta"
  """
  # ideally the assembly file is passed in directly
  medaka_consensus \\
    -i ${trimmed_fq} \\
    -d ${fa_path} \\
    -o ./ \\
    -t ${task.cpus}
  """
}
