process raven_assembly {
  tag "ASSEMBLING GENOME WITH RAVEN: ${barcode}"
  container 'quay.io/biocontainers/raven-assembler:1.8.3--h5ca1c30_3'

  input:
  tuple val(barcode), path(trimmed_fq)

  output:
  tuple val(barcode), path("${barcode}_raven_assembly"), emit: raven_assembly
  tuple val(barcode), val("raven"), path("${barcode}_raven_assembly/assembly_graph.gfa"), emit: raven_graph

  script: 
  """
  mkdir ${barcode}_raven_assembly
  raven \\
    --threads ${task.cpus} \\
    --disable-checkpoints \\
    --graphical-fragment-assembly ${barcode}_raven_assembly/assembly_graph.gfa \\
    ${trimmed_fq} > ${barcode}_raven_assembly/assembly.fasta
  """
}
