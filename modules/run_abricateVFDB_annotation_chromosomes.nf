process abricateVFDB_annotation_chromosomes {
  tag "VFDB GENES: ${barcode}: ${assembler}"
  container 'quay.io/biocontainers/abricate:1.0.1--ha8f3691_2'
  publishDir "${params.outdir}/annotations/${barcode}/abricate", mode: 'symlink'

  input:
  tuple val(barcode), val(assembler), path(polished_fasta)

  output:
  tuple val(barcode), path("*.txt"), emit: report

  script:
  prefix = "${barcode}_${assembler}_chr"
  db_name = 'vfdb'
  """
  abricate \\
    $polished_fasta \\
	-db ${db_name} \\
    --threads $task.cpus \\
    > ${prefix}.txt
  """

}
