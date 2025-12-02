process concat_fastqs {
  tag "CONCATENATING FASTQS WITH PIGZ: ${sample}"
  container 'quay.io/biocontainers/pigz:2.8'
    
  input:
  tuple val(sample), path(unzip_dirs)

  output:
  tuple val(sample), path("${sample}_concat.fq.gz"), emit: concat_fq

  script:
  def dirs_to_search = unzip_dirs instanceof Collection ? unzip_dirs.collect { p -> "'${p.toString()}'" }.join(' ') : "'${unzip_dirs.toString()}'"
  // TODO explore error tracing. Pigz can fail to run but reports exit status 0
  """
  UNCMPFQS=\$(find -L ${dirs_to_search} -type f -name "*.fastq" -o -name "*.fq" | sort)
  CMPFQS=\$(find -L ${dirs_to_search} -type f -name "*.fastq.gz" -o -name "*.fq.gz" | sort)

  pigz -dc \${CMPFQS} | cat - \${UNCMPFQS} | pigz -p ${task.cpus} > ${sample}_concat.fq.gz
  """
}
