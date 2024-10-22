process medaka_polish_consensus_new {
  tag "POLISHING CONSENSUS ASSEMBLY: ${barcode}"
  container 'quay.io/biocontainers/medaka:1.11.3--py39h05d5c5e_0'
  publishDir "${params.outdir}/assemblies/${barcode}_consensus", mode: 'symlink'

  input:
  tuple val(barcode), path(cluster_dir)

  output:
  tuple val(barcode), path("**/8_medaka.fasta"), emit: assembly

  script:
  """
  medaka_consensus \\
    -i ${cluster_dir}/4_reads.fastq \\
    -d ${cluster_dir}/7_final_consensus.fasta \\
    -o ${cluster_dir}/medaka \\
    -t ${task.cpus}
 
  # rename medaka files to be consistent with trycycler outputs
  mv ${cluster_dir}/medaka/consensus.fasta ${cluster_dir}/8_medaka.fasta

  # clean up according to trycycler wiki
  rm -r ${cluster_dir}/medaka ${cluster_dir}/*.fai ${cluster_dir}/*.mmi
  """
}
