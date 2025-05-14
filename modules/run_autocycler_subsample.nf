process autocycler_subsample {
  tag "SUBSAMPLING FASTQS: ${barcode}"
  container 'quay.io/biocontainers/autocycler:0.3.0--h3ab6199_0'

  // errorStrategy { task.exitStatus == 1 ? 'ignore' : 'terminate' } 

  input:
  tuple val(barcode), path(trimmed_fq), path(genome_size_txt)

  output:
  tuple val(barcode), path("${barcode}_subsets/*.fastq"), emit: subsets

  script:
  n_subsamples = params.subsamples.toInteger()
  """
  autocycler subsample \\
    --reads $trimmed_fq \\
    --out_dir ${barcode}_subsets \\
    --count ${n_subsamples} \\
    --genome_size \$(cat ${genome_size_txt})
  """
}
