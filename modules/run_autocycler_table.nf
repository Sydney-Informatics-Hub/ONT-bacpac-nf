process autocycler_table {
  tag "AUTOCYCLER TABLE: ${sample}"
  container 'quay.io/biocontainers/autocycler:0.3.0--h3ab6199_0'
  publishDir "${params.outdir}/assemblies/${sample}_consensus", mode: 'copy'

  input:
  tuple val(sample), path(autocycler_dir)

  output:
  tuple val(sample), path("${sample}_metrics.tsv"), emit: metrics

  script:
  """
  autocycler table > ${sample}_metrics.tsv  # Header row
  autocycler table \\
    --autocycler_dir autocycler_out \\
    --name ${sample} \\
    >> ${sample}_metrics.tsv
  """
}
