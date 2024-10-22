process trycycler_consensus_new {
  tag "GENERATING CONSENSUS ASSEMBLY: ${barcode}: ${cluster_dir}"
  container 'quay.io/biocontainers/trycycler:0.5.4--pyhdfd78af_0'

  input:
  tuple val(barcode), path(cluster_dir)

  output:
  tuple val(barcode), path("**/7_final_consensus.fasta"), emit: assembly

  script:
  """
  trycycler consensus \\
	--cluster_dir $cluster_dir \\
    --threads ${task.cpus}
  """
}
