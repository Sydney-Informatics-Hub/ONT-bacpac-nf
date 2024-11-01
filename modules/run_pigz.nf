process concat_fastqs {
  tag "CONCATENATING FASTQS WITH PIGZ: ${barcode}"
  container 'quay.io/biocontainers/pigz:2.8'
    
  input:
  tuple val(barcode), path(unzip_dir)

  output:
  tuple val(barcode), path("*_concat.fq.gz"), emit: concat_fq

  script:
  // TODO explore error tracing. Pigz can fail to run but reports exit status 0
  """
  fqs=\$(find -L '${unzip_dir}' -name "*.fastq.gz" | sort)

  pigz -dc \${fqs} | pigz -p ${task.cpus} \\
    > ${barcode}_concat.fq.gz
  """
}
