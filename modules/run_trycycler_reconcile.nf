process trycycler_reconcile {
  tag "RECONCILING CONTIGS: ${barcode}:${reconcile_contigs}"
  container 'quay.io/biocontainers/trycycler:0.5.4--pyhdfd78af_0'

  input:
  tuple val(barcode), path(reconcile_contigs), path(trimmed_fq)

  output: 
  tuple val(barcode), path("${reconcile_contigs}_reconciled/"), emit: reconciled_seqs, optional: true
   
  script: 
  """
  echo "Running trycycler reconcile for barcode: ${barcode}"
  echo "Input directory: ${reconcile_contigs}"
  echo "Output directory: ${reconcile_contigs}_reconciled/"
  echo "Trimmed reads: ${barcode}_trimmed.fastq.gz"

  trycycler reconcile \\
      --reads ${barcode}_trimmed.fastq.gz \\
      --cluster_dir ${reconcile_contigs} \\
      --threads ${task.cpus} \\
      --min_1kbp_identity 10 \\
      --max_add_seq 2500

  if [ -f "${reconcile_contigs}/2_all_seqs.fasta" ]; then
        echo "File 2_all_seqs.fasta found, moving to output directory."
        # Set up the output directory
        mkdir -p ${reconcile_contigs}_reconciled/
        # Move output from input directory to _reconciled output directory
        mv ${reconcile_contigs}/2_all_seqs.fasta ${reconcile_contigs}_reconciled/2_all_seqs.fasta
  else
        echo "File 2_all_seqs.fasta not found. Please check the trycycler reconcile command and input files."
  fi
  """
}
