process amrfinderplus_annotation_chromosomes {
  tag "${barcode}: ${assembler}"
  container 'quay.io/biocontainers/ncbi-amrfinderplus:3.12.8--h283d18e_0'
  publishDir "${params.outdir}/annotations/${prefix}/amrfinderplus", mode: 'copy'
  
  input:
  tuple val(barcode), val(assembler), path(annotated_faa)
  path amrfinderplus_db

  output:
  tuple val(barcode), val(assembler), path("${prefix}.tsv"), emit: report
  tuple val(barcode), val(assembler), path("${prefix}.annotated.tsv"), emit: annotated_report

  script:
  prefix = "${barcode}_${assembler}_chr"
  """
  amrfinder \\
    -p $annotated_faa \\
    -d ${amrfinderplus_db}/latest \\
    --threads $task.cpus > ${prefix}.tsv

  # Annotate the report with the sample name/barcode and assembler name
  awk -v OFS="\t" 'NR == 1 { print "Sample", "Assembler", \$0 } NR > 1 { print "${barcode}", "${assembler}", \$0 }' ${prefix}.tsv > ${prefix}.annotated.tsv
  """

}
