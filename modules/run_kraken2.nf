process kraken2 {
  tag "DETECTING POSSIBLE CONTAMINATION: ${sample}"
  container 'quay.io/biocontainers/kraken2:2.1.3--pl5321hdcf5f25_0'
  publishDir "${params.outdir}/quality_control/${sample}_kraken2", mode: 'copy'

  input:
  tuple val(sample), path(trimmed_fq)
  path kraken2_db 

  output:
  tuple val(sample), path("*.k2report"), emit: kraken2_screen

  script:
  """
  kraken2 ${trimmed_fq} \\
    --db ${kraken2_db} \\
    --report ${sample}.k2report \\
    --report-minimizer-data \\
    --minimum-hit-groups 3 \\
    --threads ${task.cpus} \\
    --output ${sample}_k2_out.txt 
  """
}
