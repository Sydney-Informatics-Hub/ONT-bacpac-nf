process abricateVFDB_annotation_chromosomes {
  tag "VFDB GENES: ${barcode}: ${assembler}"
  container 'quay.io/biocontainers/abricate:1.0.1--ha8f3691_2'
  publishDir "${params.outdir}/annotations/${prefix}/abricate", mode: 'copy'

  input:
  tuple val(barcode), val(assembler), path(polished_fasta)

  output:
  tuple val(barcode), val(assembler), path("${prefix}.tsv"), emit: report
  tuple val(barcode), val(assembler), path("${prefix}.annotated.tsv"), emit: annotated_report

  script:
  prefix = "${barcode}_${assembler}_chr"
  db_name = 'vfdb'
  """
  abricate \\
    $polished_fasta \\
    -db ${db_name} \\
    --threads $task.cpus > ${prefix}.tsv

  # Annotate the report with the sample name/barcode and assembler name
  awk -v OFS="\t" 'NR == 1 { print \$0, "SAMPLE", "ASSEMBLER" } NR > 1 { print \$0, "${barcode}", "${assembler}" }' ${prefix}.tsv > ${prefix}.annotated.tsv
  """

}
