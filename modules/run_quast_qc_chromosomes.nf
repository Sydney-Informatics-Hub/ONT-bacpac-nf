process quast_qc_chromosomes {
  tag "EVALUATING GENOME QUALITY: ${barcode}: ${assembler}"
  container 'quay.io/biocontainers/quast:5.2.0--py39pl5321h2add14b_1'
  publishDir "${params.outdir}/quality_control/${barcode}", mode: 'symlink'

  input:
  tuple val(barcode), val(assembler), path(polished_assembly)

  output:
  tuple val(barcode), val(assembler), path("${prefix}"), emit: results
  tuple val(barcode), val(assembler), path("${prefix}.tsv"), emit: tsv

  script:
  prefix = "${barcode}_${assembler}"
  """
  quast.py \\
    --output-dir $prefix \\
    $polished_assembly \\
    --threads $task.cpus

  # multiqc requires tsv to be named with sample
  ln -s ${prefix}/report.tsv ${prefix}.tsv
  """

}
