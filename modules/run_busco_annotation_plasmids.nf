process busco_annotation_plasmids {
  tag "ANNOTATING PLASMIDS WITH BUSCO: ${barcode}"
  container 'quay.io/biocontainers/busco:5.6.1--pyhdfd78af_0'
  publishDir "${params.outdir}/assemblies/${barcode}_plasmids", mode: 'symlink'

input:
  tuple val(barcode), path(bakta_annotations)

output:
  //tuple val(barcode), path("${barcode}_plasmids_busco/short_summary.specific.*_busco.txt"), emit: busco_annotations
  tuple val(barcode), path("${barcode}_*"), emit: busco_annotations

script:
  """
  busco \\
    -f -i ${barcode}_bakta/${barcode}_plasmids.faa \\
    -m proteins \\
    --lineage_dataset bacteria_odb10 \\
    --out ${barcode}_plasmids_busco
  """

}