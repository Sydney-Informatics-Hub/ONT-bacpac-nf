process medaka_polish_flye {
  tag "POLISHING FLYE ASSEMBLY: ${barcode}"
  container 'quay.io/biocontainers/medaka:1.11.3--py39h05d5c5e_0'
  publishDir "${params.outdir}/assemblies/${barcode}_flye", mode: 'symlink'

  input:
  tuple val(barcode), path(flye_assembly), path(trimmed_fq)

  output:
  tuple val(barcode), path("*"), emit: flye_polished, optional: true

  script:
  """
  medaka_consensus \\
	 -i ${trimmed_fq} \\
	 -d ${flye_assembly}/assembly.fasta \\
	 -o ${barcode}_polished \\
	 -t ${task.cpus}
  """
}
