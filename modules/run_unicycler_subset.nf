process unicycler_assembly_subset {
  tag "ASSEMBLING SUBSET GENOME WITH UNICYCLER: ${barcode}"
  container 'quay.io/biocontainers/unicycler:0.4.8--py38h8162308_3'
  //publishDir "${params.outDir}", mode: 'symlink'

  input:
  tuple val(barcode), path(subset_fq)

  output:
  tuple val(barcode), path("*"), emit: unicycler_assembly

  script: 
  """
  SUBSAMPLEIDX=\$(basename ${subset_fq} .fastq | cut -d '_' -f 2)
  OUTDIR="${barcode}_\${SUBSAMPLEIDX}_unicycler_assembly"
  unicycler \
    --long ${subset_fq} \\
    --threads ${task.cpus} \\
    --out \${OUTDIR}
  """
}
