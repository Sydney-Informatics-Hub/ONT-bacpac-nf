process busco_qc {
  tag "EVALUATING GENOME COMPLETENESS: ${assembler_name}: ${barcode}"
  container 'quay.io/biocontainers/busco:5.6.1--pyhdfd78af_0'
  publishDir "${params.outdir}/quality_control/${barcode}", mode: 'symlink'

  input:
  tuple val(barcode), val(assembler_name), path(polished_assembly)
  path(busco_db)

  output:
  tuple val(barcode), val(assembler_name), path("${assembler_name}_busco/"), emit: results
  tuple val(barcode), val(assembler_name), path("${assembler_name}_busco/short_summary.specific.*.txt"), emit: summary
  tuple val(barcode), path("${assembler_name}_busco/short_summary.specific.*.json"), emit: json 

  script:
  """
  busco \\
    -i ${polished_assembly} \\
    -m genome \\
    --lineage_dataset ${busco_db}/lineages/bacteria_odb10 \\
    --out ${assembler_name}_busco \\
    --force --offline
  """

}
