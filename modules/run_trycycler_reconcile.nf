process trycycler_reconcile {
  tag "CLUSTERING CONTIGS: ${barcode}"
  container 'quay.io/biocontainers/trycycler:0.5.4--pyhdfd78af_0'

  input:
  tuple val(barcode), path(reconcile_contigs), path(trimmed_fq)

  script: 
  """
  trycycler reconcile \\
      --reads ${barcode}_trimmed.fastq.gz \\
      --cluster_dir ${reconcile_contigs} \\
      --threads ${task.cpus} \\
      --min_1kbp_identity 10 \\
      --max_add_seq 2500
  """
}
