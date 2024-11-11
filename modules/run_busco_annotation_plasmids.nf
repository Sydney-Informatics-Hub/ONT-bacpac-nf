process busco_annotation_plasmids {
  tag "EVALUATING PLASMID COMPLETENESS: ${barcode}"
  container 'quay.io/biocontainers/busco:5.6.1--pyhdfd78af_0'
  publishDir "${params.outdir}/assemblies/${barcode}/plasmids", mode: 'copy'

input:
  tuple val(barcode), path(bakta_annotations)

output:
  //tuple val(barcode), path("${barcode}_plasmids_busco/short_summary.specific.*_busco.txt"), emit: busco_annotations
  tuple val(barcode), path("busco/*"), emit: busco_annotations

script:
  """
  busco \\
    -f -i ${barcode}_bakta/${barcode}_plasmids.faa \\
    -m proteins \\
    --lineage_dataset bacteria_odb10 \\
    --out busco
  """

}
