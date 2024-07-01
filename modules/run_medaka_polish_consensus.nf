process medaka_polish_consensus {
  tag "POLISHING CONSENSUS ASSEMBLY: ${barcode}"
  container 'quay.io/biocontainers/medaka:1.11.3--py39h05d5c5e_0'

  input:
  tuple val(barcode), path(consensus_partition), path(consensus_consensus)

  output:
  tuple val(barcode), path("*"), emit: consensus_polished, optional: true

  script:
  """
  # Make a faux input directory to meet medaka's expectations 
  cp consensus_out/7_final_consensus.fasta ./7_final_consensus.fasta

  medaka_consensus \\
		-i 4_reads.fastq \\
		-d 7_final_consensus.fasta \\
		-o medaka_consensus \\
		-t ${task.cpus}
  """
}
