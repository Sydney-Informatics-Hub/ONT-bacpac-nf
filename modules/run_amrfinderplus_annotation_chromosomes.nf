process amrfinderplus_annotation_chromosomes {
  tag "${sample}: ${assembler}"
  container 'quay.io/biocontainers/ncbi-amrfinderplus:3.12.8--h283d18e_0'
  publishDir "${params.outdir}/annotations/${prefix}/amrfinderplus", mode: 'copy'
  
  input:
  tuple val(sample), val(assembler), path(annotated_faa)
  path amrfinderplus_db

  output:
  tuple val(sample), val(assembler), path("${prefix}.tsv"), emit: report
  tuple val(sample), val(assembler), path("${prefix}.annotated.tsv"), emit: annotated_report

  script:
  prefix = "${sample}_${assembler}_chr"
  """
  amrfinder \\
    -p $annotated_faa \\
    -d ${amrfinderplus_db}/latest \\
    --threads $task.cpus > ${prefix}.tsv

  # Annotate the report with the sample name and assembler name
  awk -v OFS="\t" 'NR == 1 { print "Sample", "Assembler", \$0 } NR > 1 { print "${sample}", "${assembler}", \$0 }' ${prefix}.tsv > ${prefix}.annotated.tsv
  """

}
