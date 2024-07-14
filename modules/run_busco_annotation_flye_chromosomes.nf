process busco_annotation_flye_chromosomes {
  tag "ANNOTATING FLYECHR WITH BUSCO: ${barcode}"
  container 'quay.io/biocontainers/busco:5.6.1--pyhdfd78af_0'

input:
  tuple val(barcode), path(bakta_annotations)

output:
  tuple val(barcode), path("${barcode}_busco"), emit: busco_annotations

script:
  """
  busco \\
    -f -i ${bakta_annotations}/${barcode}.faa \
    -m proteins --lineage_dataset bacteria_odb10 \\
    --out ${barcode}_busco
  """

}
