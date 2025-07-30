process trycycler_cluster {
  tag "CLUSTERING CONTIGS: ${barcode}"
  container 'quay.io/biocontainers/trycycler:0.5.4--pyhdfd78af_0'

  // Contigs can be filtered out to be < 2 within the process and segfault
  errorStrategy { task.exitStatus == 1 ? 'ignore' : 'terminate' } 

  input:
  tuple val(barcode), path(assembly_dirs), path(trimmed_fq), val(num_contigs)

  output:
  tuple val(barcode), path("${barcode}_cluster/"), emit: clusters
  tuple val(barcode), path("${barcode}_cluster/contigs.phylip"), emit: phylip

  script:
  def assembly_dirs_concat = assembly_dirs.join(',')
  """
  trycycler cluster \\
    --assemblies {${assembly_dirs_concat}}/assembly.fasta \\
    --reads $trimmed_fq \\
    --out_dir ${barcode}_cluster \\
    --min_contig_len ${params.trycycler_min_contig_length} \\
    --threads ${task.cpus}
  """
}
