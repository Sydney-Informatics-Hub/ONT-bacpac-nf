process raven_assembly_subset {
  tag "ASSEMBLING SUBSET GENOME WITH RAVEN: ${barcode}"
  container 'quay.io/biocontainers/raven-assembler:1.8.3--h5ca1c30_3'

  input:
  tuple val(barcode), path(subset_fq)

  output:
  tuple val(barcode), path("${barcode}_*_raven_assembly"), emit: raven_assembly

  script: 
  """
  SUBSAMPLEIDX=\$(basename ${subset_fq} .fastq | cut -d '_' -f 2)
  OUTDIR="${barcode}_\${SUBSAMPLEIDX}_raven_assembly"
  mkdir \${OUTDIR}
  raven \\
    --threads ${task.cpus} \\
    --disable-checkpoints \\
    --graphical-fragment-assembly \${OUTDIR}/assembly_graph.gfa \\
    ${subset_fq} > \${OUTDIR}/assembly.fasta
  """
}
