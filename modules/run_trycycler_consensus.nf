process trycycler_consensus {
  tag "GENERATING CONSENSUS ASSEMBLY: ${barcode}"
  container 'quay.io/biocontainers/trycycler:0.5.4--pyhdfd78af_0'

  input:
  tuple val(barcode), path(consensus_partition), path(consensus_good), path(consensus_msa)

  when:
  consensus_good.exists()

  output:
  // TODO fix this output to capture stdout and msa fasta separately
  tuple val(barcode), path("*"), emit: consensus_msa

  script:
  """
  # Make a faux input directory to meet trycycler's expectations 
  mkdir -p consensus_in

  # Capture path to 2_all_seqs.fasta
  reconciled_dir=\$(ls -d */* | grep 'barcode[0-9]*_final/cluster_[0-9]*_reconciled')
  cp \${reconciled_dir}/2_all_seqs.fasta consensus_in/.

  # Capture path to 3_msa.fasta 
  cp 3_msa.fasta consensus_in/.

  # Capture path to 4_reads.fastq 
  cp 4_reads.fastq consensus_in/.
  
  # Run trycycler reconcile step 
  trycycler consensus \\
			--cluster_dir consensus_in/. \\
      --threads ${task.cpus}

  # Save output to new directory
  mkdir -p consensus_out
  mv consensus_in/5_chunked_sequence.gfa consensus_out/5_chunked_sequence.gfa
  mv consensus_in/6_initial_consensus.fasta consensus_out/6_initial_consensus.fasta
  mv consensus_in/7_final_consensus.fasta consensus_out/7_final_consensus.fasta
  """
}
