process bakta_annotation_plasmids {
  tag "ANNOTATING PLASMIDS WITH BATKA: ${barcode}"
  container 'quay.io/biocontainers/bakta:1.9.2--pyhdfd78af_0'

input:
  tuple val(barcode), path(plassembler_plasmids)
  path(bakta_db)

output:
  tuple val(barcode), path("${barcode}_bakta"), emit: bakta_annotations    
  tuple val(barcode), path("${barcode}_bakta/*.txt"), emit: bakta_annotations_multiqc

  publishDir { "results/${barcode}" }, mode: 'copy'

script:
  """
  bakta \\
    ${plassembler_plasmids} \\
    --db ${bakta_db} \\
    --output ${barcode}_bakta \\
    --prefix ${barcode}_plasmids \\
    --force \\
    --threads ${task.cpus}
  """

}
