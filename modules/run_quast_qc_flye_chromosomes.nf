process quast_qc_flye_chromosomes {
  tag "EVALUATING GENOME QUALITY: ${barcode}"
  container 'quay.io/biocontainers/quast:5.2.0--py39pl5321h2add14b_1'
  publishDir "${params.outdir}/annotations/${barcode}", mode: 'symlink'

input:
  tuple val(barcode), path(medaka_flye)

output:
  tuple val(barcode), path("${barcode}_quast"), emit: quast_qc
  tuple val(barcode), path("${barcode}_quast/${barcode}.tsv"), emit: quast_qc_multiqc

script:
  """

  quast.py \\
        --output-dir ${barcode}_quast \\
        -l ${barcode} \\
        ${medaka_flye}/consensus.fasta

  mv ${barcode}_quast/report.tsv ${barcode}_quast/${barcode}.tsv 
  """

}
