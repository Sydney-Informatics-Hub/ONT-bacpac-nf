process busco_annotation_plasmids {
  tag "EVALUATING PLASMID COMPLETENESS: ${barcode}"
  container 'quay.io/biocontainers/busco:5.6.1--pyhdfd78af_0'
  publishDir "${params.outdir}/quality_control/${barcode}", mode: 'copy'

input:
  tuple val(barcode), path(assembly)
  path(busco_db)

output:
  tuple val(barcode), path("${prefix}"), emit: results
  tuple val(barcode), path("${prefix}/short_summary.*.txt"), emit: txt_summary
  tuple val(barcode), path("${prefix}/short_summary.*.json"), emit: json_summary

// NOTE: I have re-worked this process to match the busco_qc_chromosomes process
// However, note that a) this process isn't used at all yet, and b) I'm not 100%
// sure why we are using the protein mode.
script:
  prefix = "${barcode}_plassembler_busco"
  """
  busco \\
    --cpu $task.cpus \\
    --in $assembly \\
    --out ${prefix} \\
    --mode protein \\
    --lineage_dataset busco_downloads/lineages/bacteria_odb* \\
    --force \\
    --offline
  """

}
