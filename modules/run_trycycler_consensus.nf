process trycycler_consensus {
  tag "GENERATING CONSENSUS ASSEMBLY: ${barcode}"
  container 'quay.io/biocontainers/trycycler:0.5.4--pyhdfd78af_0'

  input:
  tuple val(barcode), path(consensus_in)


  //output:
  // TODO fix this output to capture stdout and msa fasta separately
  //tuple val(barcode), path("consensus_out/"), emit: consensus_consensus

  script:

  """
  echo "Barcode: ${barcode}"
  echo "${consensus_in}"	
  #consensus_in_dir=\$(dirname '$consensus_in')
  #echo "\${consensus_in_dir}"
	
  # Run trycycler reconcile step 
  trycycler consensus \\
	--cluster_dir ./ \\
        --threads ${task.cpus}

  # Save output to new directory
  #mkdir -p consensus_out
  #mv consensus_in/5_chunked_sequence.gfa consensus_out/5_chunked_sequence.gfa
  #mv consensus_in/6_initial_consensus.fasta consensus_out/6_initial_consensus.fasta
  #mv consensus_in/7_final_consensus.fasta consensus_out/7_final_consensus.fasta
  """
}
