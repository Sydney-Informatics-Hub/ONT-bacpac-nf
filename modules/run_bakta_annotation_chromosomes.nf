process bakta_annotation_chromosomes {
  tag "GENE FEATURES: ${barcode}: ${assembler}"
  container 'quay.io/biocontainers/bakta:1.9.2--pyhdfd78af_0'
  publishDir "${params.outdir}/annotations/${barcode}/bakta", mode: 'copy'

  input:
  tuple val(barcode), val(assembler), path(polished_fasta)
  path(bakta_db)

  output:
  tuple val(barcode), val(assembler), path("${prefix}.faa"), emit: faa
  tuple val(barcode), val(assembler), path("${prefix}.txt"), emit: txt
  tuple val(barcode), val(assembler), path("${prefix}.gff3"), emit: gff

  script:
  prefix = "${barcode}_${assembler}_chr"
  """
  bakta \\
    $polished_fasta \\
    --db $bakta_db \\
    --prefix $prefix \\
    --force \\
    --threads ${task.cpus}
  """
}
