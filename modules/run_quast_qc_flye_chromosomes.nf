process quast_qc_flye_chromosomes {
  tag "QC Flye-only assembly WITH quast: ${barcode}"
  container 'quay.io/biocontainers/quast:5.2.0--py39pl5321h2add14b_1'


input:
  tuple val(barcode), path(medaka_flye)

output:
  tuple val(barcode), path("${barcode}_quast"), emit: quast_qc

  publishDir { "results/${barcode}" }, mode: 'copy'

script:
  """

  quast.py \\
        --output-dir ${barcode}_quast \\
        -l ${barcode} \\
        ${medaka_flye}/consensus.fasta 
  """

}
