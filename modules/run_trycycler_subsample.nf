process trycycler_subsample {
  tag "SUBSAMPLING FASTQS: ${barcode}"
  container 'quay.io/biocontainers/trycycler:0.5.4--pyhdfd78af_0'

  // errorStrategy { task.exitStatus == 1 ? 'ignore' : 'terminate' } 

  input:
  tuple val(barcode), path(trimmed_fq)

  output:
  tuple val(barcode), path("${barcode}_subsets/*.fastq"), emit: subsets

  script:
  """
  trycycler subsample \\
    --reads $trimmed_fq \\
    --out_dir ${barcode}_subsets \\
    --threads ${task.cpus}
  """
}
