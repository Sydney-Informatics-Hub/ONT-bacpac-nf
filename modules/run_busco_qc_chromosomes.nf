process busco_qc_chromosomes {
  tag "EVALUATING GENOME COMPLETENESS: ${sample}: ${assembler}"
  container 'quay.io/biocontainers/busco:5.6.1--pyhdfd78af_0'
  publishDir "${params.outdir}/quality_control/${sample}", mode: 'copy'
  
  input:
  tuple val(sample), val(assembler), path(polished_assembly)
  path(busco_db)
  
  output:
  tuple val(sample), val(assembler), path("${prefix}"), emit: results
  tuple val(sample), val(assembler), path("${prefix}/short_summary.*.txt"), emit: txt_summary
  tuple val(sample), val(assembler), path("${prefix}/short_summary.*.json"), emit: json_summary

  script:
  prefix = "${sample}_${assembler}_busco"
  """
  busco \\
    --cpu $task.cpus \\
    --in $polished_assembly \\
    --out ${prefix} \\
    --mode genome \\
    --lineage_dataset busco_downloads/lineages/bacteria_odb10 \\
    --force \\
    --offline
  """
}
