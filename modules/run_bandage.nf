process bandage {
  tag "BANDAGE: ${sample} - ${assembly}"
  container 'quay.io/biocontainers/bandage:0.9.0--h9948957_0'
  publishDir "${params.outdir}/assemblies/${sample}_${assembly}", mode: 'copy'

  input:
  tuple val(sample), val(assembly), path(gfa_file)

  output:
  tuple val(sample), val(assembly), path("${sample}.${assembly}.assembly.svg"), emit: bandage_plot

  script:
  """
  Bandage image ${gfa_file} ${sample}.${assembly}.assembly.svg
  """
}
