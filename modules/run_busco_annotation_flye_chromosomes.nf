process busco_annotation_flye_chromosomes {
  tag "EVALUATING GENOME COMPLETENESS: ${barcode}"
  container 'quay.io/biocontainers/busco:5.6.1--pyhdfd78af_0'
  publishDir "${params.outdir}/annotations/${barcode}", mode: 'symlink'

input:
  tuple val(barcode), path(bakta_annotations)

output:
  tuple val(barcode), path("${barcode}_busco/short_summary.specific.*.txt"), emit: busco_annotations

script:
  """
  busco \\
    -f -i ${bakta_annotations}/${barcode}_chr.faa \
    -m proteins --lineage_dataset bacteria_odb10 \\
    --out ${barcode}_busco
  """

}
