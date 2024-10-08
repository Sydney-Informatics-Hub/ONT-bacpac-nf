process quast_qc {
  tag "EVALUATING GENOME QUALITY: ${assembler_name}: ${barcode}"
  container 'quay.io/biocontainers/quast:5.2.0--py39pl5321h2add14b_1'
  publishDir "${params.outdir}/quality_control/${barcode}", mode: 'symlink'

input:
  tuple val(barcode), val(assembler_name), path(medaka_polished)

output:
  tuple val(barcode), val(assembler_name), path("${assembler_name}_quast/"), emit: results 
  tuple val(barcode), val(assembler_name), path("${assembler_name}_quast/transposed_report.tsv"), emit: transposed_tsv

script:
  """
  quast.py \\
      --output-dir ${assembler_name}_quast \\
      -l ${assembler_name} \\
      ${medaka_polished}/consensus.fasta
  """

}
