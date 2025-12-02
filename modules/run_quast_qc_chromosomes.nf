process quast_qc_chromosomes {
  tag "EVALUATING GENOME QUALITY: ${sample}: ${assembler}"
  container 'quay.io/biocontainers/quast:5.2.0--py39pl5321h2add14b_1'
  publishDir "${params.outdir}/quality_control/${sample}", mode: 'copy'

  input:
  tuple val(sample), val(assembler), path(polished_assembly)

  output:
  tuple val(sample), val(assembler), path("${prefix}"), emit: results
  tuple val(sample), val(assembler), path("${prefix}.tsv"), emit: tsv

  script:
  prefix = "${sample}_${assembler}"
  """
  quast.py \\
    --output-dir $prefix \\
    --labels ${prefix}_chr \\
    $polished_assembly \\
    --threads $task.cpus

  # multiqc requires tsv to be named with sample
  ln -s ${prefix}/report.tsv ${prefix}.tsv
  """

}
