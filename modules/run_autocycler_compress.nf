process autocycler_compress {
  tag "AUTOCYCLER COMPRESS: ${barcode}"
  container 'quay.io/biocontainers/autocycler:0.3.0--h3ab6199_0'

  // errorStrategy { task.exitStatus == 1 ? 'ignore' : 'terminate' } 

  input:
  tuple val(barcode), path(assembly_fastas)

  output:
  tuple val(barcode), path("autocycler_compress_out"), emit: compressed

  script:
  """
  mkdir assemblies
  for d in ${assembly_fastas}
  do
    cp \$d/assembly.fasta assemblies/\$(basename \$d).fasta
  done

  autocycler compress \\
    --assemblies_dir assemblies \\
    --autocycler_dir autocycler_compress_out \\
    --threads ${task.cpus}
  """
}
