process flye_assembly {
  tag "ASSEMBLING GENOME WITH FLYE: ${barcode}"
  container 'quay.io/biocontainers/flye:2.9.3--py310h2b6aa90_0'

  input:
  tuple val(barcode), path(trimmed_fq)

  output:
  tuple val(barcode), path("*"), emit: flye_assembly
  tuple val(barcode), val("flye"), path("${barcode}_flye_assembly/assembly_graph.gfa"), emit: flye_graph

  script: 
  """
  flye \\
    --nano-hq ${trimmed_fq} \\
    --threads ${task.cpus} \\
    --out-dir ${barcode}_flye_assembly
  """
}
