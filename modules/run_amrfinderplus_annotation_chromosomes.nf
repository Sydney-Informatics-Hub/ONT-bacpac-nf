process amrfinderplus_annotation_chromosomes {
  tag "${barcode}: ${assembler}"
  container 'quay.io/biocontainers/ncbi-amrfinderplus:3.12.8--h283d18e_0'
  publishDir "${params.outdir}/annotations/${barcode}/amrfinder", mode: 'symlink'
  
  input:
  tuple val(barcode), val(assembler), path(annotated_faa)
  path(amrfinderplus_db)

  output:
  tuple val(barcode), val(assembler), path("${prefix}.tsv"), emit: report

  script:
  prefix = "${barcode}_${assembler}_chr"
  """
  amrfinder \\
    -p $annotated_faa \\
    -d ${amrfinderplus_db}/latest \\
    --threads $task.cpus > ${prefix}.tsv
  """

}
