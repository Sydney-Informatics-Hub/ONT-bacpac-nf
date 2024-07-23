process busco_annotation_chromosomes {
  tag "ANNOTATING Consensus WITH BUSCO: ${barcode}"
  container 'quay.io/biocontainers/busco:5.6.1--pyhdfd78af_0'
  publishDir "${params.outdir}/assemblies/${barcode}_consensus", mode: 'symlink'
  
input:
  tuple val(barcode), path(bakta_annotations)

output:
  tuple val(barcode), path("${barcode}_busco/short_summary.specific.*_busco.txt"), emit: busco_annotations

script:
  """
  busco \\
    -f -i ${bakta_annotations}/${barcode}.faa \
    -m proteins --lineage_dataset bacteria_odb10 \\
    --out ${barcode}_busco
  """

}
