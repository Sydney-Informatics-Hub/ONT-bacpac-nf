process trycycler_consensus {
  tag "GENERATING CONSENSUS ASSEMBLY: ${barcode}"
  container 'quay.io/biocontainers/trycycler:0.5.4--pyhdfd78af_0'

  input:
  tuple val(barcode), val(cluster_id), path(msa), path(twoseq_and_partition)

  output:
  tuple val(barcode), val("${cluster_id}"), path("consensus_out"), emit: consensus_consensus


  script:

  """
  # Make a faux input directory to meet trycycler's expectations
  mkdir -p consensus_in
 
  # Capture path to 2_all_seqs.fasta
  cp ${twoseq_and_partition}/2_all_seqs.fasta consensus_in/

  # Capture path to 3_msa.fasta
  cp ${msa}/3_msa.fasta consensus_in/

  # Capture path to 4_reads.fastq
  cp ${twoseq_and_partition}/4_reads.fastq consensus_in/
	
  # Run trycycler reconcile step 
  trycycler consensus \\
	--cluster_dir consensus_in \\
        --threads ${task.cpus}

  # Save output to new directory
  mkdir -p consensus_out
  cp consensus_in/5_chunked_sequence.gfa consensus_out/5_chunked_sequence.gfa
  cp consensus_in/6_initial_consensus.fasta consensus_out/6_initial_consensus.fasta
  cp consensus_in/7_final_consensus.fasta consensus_out/7_final_consensus.fasta
  """
}
