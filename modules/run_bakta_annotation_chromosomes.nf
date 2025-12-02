process bakta_annotation_chromosomes {
  tag "GENE FEATURES: ${sample}: ${assembler}"
  container 'quay.io/biocontainers/bakta:1.9.2--pyhdfd78af_0'
  publishDir "${params.outdir}/annotations/${prefix}/bakta", mode: 'copy'

  input:
  tuple val(sample), val(assembler), path(polished_fasta)
  path(bakta_db)

  output:
  tuple val(sample), val(assembler), path("${prefix}.faa"), emit: faa
  tuple val(sample), val(assembler), path("${prefix}.txt"), emit: txt
  tuple val(sample), val(assembler), path("${prefix}.gff3"), emit: gff

  script:
  prefix = "${sample}_${assembler}_chr"
  """
  bakta \\
    $polished_fasta \\
    --db $bakta_db \\
    --prefix $prefix \\
    --force \\
    --threads ${task.cpus}
  """
}
