process bakta_annotation_plasmids {
  tag "ANNOTATING PLASMIDS: ${sample}"
  container 'quay.io/biocontainers/bakta:1.9.2--pyhdfd78af_0'
  publishDir "${params.outdir}/annotations/${sample}/plasmids", mode: 'copy'
  
input:
  tuple val(sample), path(plassembler_plasmids)
  path(bakta_db)

output:
  tuple val(sample), path("${sample}_bakta/"), emit: bakta_annotations    
  tuple val(sample), path("${sample}_bakta/${sample}_plasmids.txt"), emit: bakta_annotations_multiqc

script:
  """
  bakta \\
    ${plassembler_plasmids} \\
    --db ${bakta_db} \\
    --output ${sample}_bakta/ \\
    --prefix ${sample}_plasmids \\
    --force \\
    --threads ${task.cpus}
  """

}
