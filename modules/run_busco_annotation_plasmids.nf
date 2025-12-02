process busco_annotation_plasmids {
  tag "EVALUATING PLASMID COMPLETENESS: ${sample}"
  container 'quay.io/biocontainers/busco:5.6.1--pyhdfd78af_0'
  publishDir "${params.outdir}/assemblies/${sample}/plasmids", mode: 'copy'

input:
  tuple val(sample), path(bakta_annotations)

output:
  //tuple val(sample), path("${sample}_plasmids_busco/short_summary.specific.*_busco.txt"), emit: busco_annotations
  tuple val(sample), path("busco/*"), emit: busco_annotations

script:
  """
  busco \\
    -f -i ${sample}_bakta/${sample}_plasmids.faa \\
    -m proteins \\
    --lineage_dataset bacteria_odb10 \\
    --out busco
  """

}
