process trycycler_reconcile {
  tag "RECONCILING CONTIGS: ${barcode}:${reconcile_contigs}"
  container 'quay.io/biocontainers/trycycler:0.5.4--pyhdfd78af_0'

  input:
  tuple val(barcode), path(reconcile_contigs), path(trimmed_fq)

  output: 
  tuple val(barcode), path("cluster*_reconciled/"), emit: reconciled, optional: true
   
  script: 
  """
  # TODO add appropriate error handling to collect error message printed to screen

  # Set up the output directory
  mkdir -p ${reconcile_contigs}_reconciled/

  trycycler reconcile \\
      --reads ${barcode}_trimmed.fastq.gz \\
      --cluster_dir ${reconcile_contigs} \\
      --threads ${task.cpus} \\
      --min_1kbp_identity 10 \\
      --max_add_seq 2500

  if [ -f "${reconcile_contigs}/2_all_seqs.fasta" ]; then
        # Move output from input directory to _reconciled output directory
        mv ${reconcile_contigs}/2_all_seqs.fasta ${reconcile_contigs}_reconciled/2_all_seqs.fasta
  fi
  """
}
