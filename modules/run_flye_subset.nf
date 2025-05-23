process flye_assembly_subset {
  tag "ASSEMBLING SUBSET GENOME WITH FLYE: ${barcode}"
  container 'quay.io/biocontainers/flye:2.9.3--py310h2b6aa90_0'

  input:
  tuple val(barcode), path(subset_fq)

  output:
  tuple val(barcode), path("*"), emit: flye_assembly

  script: 
  """
  SUBSAMPLEIDX=\$(basename ${subset_fq} .fastq | cut -d '_' -f 2)
  OUTDIR="${barcode}_\${SUBSAMPLEIDX}_flye_assembly"
  flye \\
    --nano-hq ${subset_fq} \\
    --threads ${task.cpus} \\
    --out-dir \${OUTDIR}
  """
}
