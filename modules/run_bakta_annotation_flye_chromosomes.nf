process bakta_annotation_flye_chromosomes {
  tag "ANNOTATING Flye-only assembly WITH BATKA: ${barcode}"
  container 'quay.io/biocontainers/bakta:1.9.2--pyhdfd78af_0'

input:
  tuple val(barcode), path(medaka_flye)
  path(bakta_db)

output:
  tuple val(barcode), path("${barcode}_bakta"), emit: bakta_annotations    

  publishDir { "results/${barcode}" }, mode: 'copy'

script:
  """
  bakta \\
    ${medaka_flye}/consensus.fasta \\
    --db ${bakta_db} \\
    --output ${barcode}_bakta \\
    --prefix ${barcode} \\
    --force \\
    --threads ${task.cpus}
   
  """

}
