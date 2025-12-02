process autocycler_subsample {
  tag "SUBSAMPLING FASTQS: ${sample}"
  container 'quay.io/biocontainers/autocycler:0.3.0--h3ab6199_0'

  input:
  tuple val(sample), path(trimmed_fq), path(genome_size_txt)

  output:
  tuple val(sample), path("${sample}_subsets/*.fastq"), emit: subsets

  script:
  n_subsamples = params.subsamples.toInteger()
  """
  autocycler subsample \\
    --reads $trimmed_fq \\
    --out_dir ${sample}_subsets \\
    --count ${n_subsamples} \\
    --genome_size \$(cat ${genome_size_txt})
  """
}
