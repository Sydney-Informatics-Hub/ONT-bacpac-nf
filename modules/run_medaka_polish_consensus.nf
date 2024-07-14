process medaka_polish_consensus {
  tag "POLISHING CONSENSUS ASSEMBLY: ${barcode}"
  container 'quay.io/biocontainers/medaka:1.11.3--py39h05d5c5e_0'

  input:
  tuple val(barcode), val(cluster_id), path(consensus_partition), path(consensus_consensus)  

  output:
  tuple val(barcode), val(cluster_id), path("medaka_consensus/${cluster_id}"), emit: consensus_polished, optional: true

  script:
  """
  medaka_consensus \\
		-i ${consensus_partition}/4_reads.fastq \\
		-d ${consensus_consensus}/7_final_consensus.fasta \\
		-o medaka_consensus/${cluster_id} \\
		-t ${task.cpus}
  """
}
