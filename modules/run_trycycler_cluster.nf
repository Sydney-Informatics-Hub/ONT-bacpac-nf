process trycycler_cluster {
  tag "CLUSTERING CONTIGS: ${barcode}"
  container 'quay.io/biocontainers/trycycler:0.5.4--pyhdfd78af_0'

  // Contigs can be filtered out to be < 2 within the process and segfault
  errorStrategy { task.exitStatus == 1 ? 'ignore' : 'terminate' } 

  input:
  tuple val(barcode), path(unicycler_assembly), path(flye_assembly), path(trimmed_fq), val(num_contigs)

  output:
  tuple val(barcode), path("${barcode}_cluster/"), emit: clusters
  tuple val(barcode), path("${barcode}_cluster/contigs.phylip"), emit: phylip

  script:
  """
  trycycler cluster \\
    --assemblies ${unicycler_assembly}/assembly.fasta ${flye_assembly}/assembly.fasta \\
    --reads $trimmed_fq \\
    --out_dir ${barcode}_cluster \\
    --min_contig_len ${params.trycycler_min_contig_length} \\
    --threads ${task.cpus}
  """
}
