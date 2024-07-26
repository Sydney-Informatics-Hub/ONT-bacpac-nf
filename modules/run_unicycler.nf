process unicycler_assembly {
  tag "ASSEMBLING GENOME WITH UNICYCLER: ${barcode}"
  container 'quay.io/biocontainers/unicycler:0.4.8--py38h8162308_3'
  //publishDir "${params.outDir}", mode: 'symlink'

  input:
  tuple val(barcode), path(trimmed_fq)

  output:
  tuple val(barcode), path("*"), emit: unicycler_assembly

  script: 
  """
  unicycler \
    --long ${trimmed_fq} \\
    --threads ${task.cpus} \\
    --out ${barcode}_unicycler_assembly
  """
}
