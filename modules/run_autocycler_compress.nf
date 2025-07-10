process autocycler_compress {
  tag "AUTOCYCLER COMPRESS: ${barcode}"
  container 'quay.io/biocontainers/autocycler:0.3.0--h3ab6199_0'
  // Autocycler compress can fail if the assembly is too fragmented
  // We can allow this and fall back to using the de novo assemblers
  errorStrategy { task.exitStatus == 1 ? 'ignore' : 'finish' }

  input:
  tuple val(barcode), path(assembly_fastas)

  output:
  tuple val(barcode), path("autocycler_compress_out"), emit: compressed

  script:
  max_contigs_param = params.max_contigs && params.max_contigs.toString().isInteger() ? "--max_contigs ${params.max_contigs}" : ""
  """
  mkdir assemblies
  for d in ${assembly_fastas}
  do
    cp \$d/assembly.fasta assemblies/\$(basename \$d).fasta
  done

  autocycler compress \\
    --assemblies_dir assemblies \\
    --autocycler_dir autocycler_compress_out \\
    ${max_contigs_param} \\
    --threads ${task.cpus}
  """
}
