process trycycler_cluster {
  tag "CLUSTERING CONTIGS: ${barcode}"
  container 'quay.io/biocontainers/trycycler:0.5.4--pyhdfd78af_0'

  errorStrategy 'ignore' // Ignore the error status

  input:
  tuple val(barcode), path(unicycler_assembly), path(flye_assembly), path(trimmed_fq)

  output:
  tuple val(barcode), path("*"), path("${barcode}_cluster/contigs.phylip"), emit: trycycler_cluster

  script: 
  """
  trycycler cluster \\
    --assemblies ${barcode}_unicycler_assembly/assembly.fasta ${barcode}_flye_assembly/assembly.fasta \\
    --reads ${barcode}_trimmed.fastq.gz \\
    --out_dir ${barcode}_cluster \\
    --min_contig_len ${params.trycycler_min_contig_length} \\
    --threads ${task.cpus}  || true
  """
}
