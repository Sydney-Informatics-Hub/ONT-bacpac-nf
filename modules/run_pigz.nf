process concat_fastqs {
  tag "CONCATENATING FASTQS WITH PIGZ: ${barcode}"
  container 'quay.io/biocontainers/pigz:2.8'
    
  input:
  tuple val(barcode), path(unzip_dir)

  output:
  tuple val(barcode), path("${barcode}_concat.fq.gz"), emit: concat_fq

  script:
  // TODO explore error tracing. Pigz can fail to run but reports exit status 0
  """
  UNCMPFQS=\$(find -L '${unzip_dir}' -type f -name "*.fastq" -o -name "*.fq" | sort)
  CMPFQS=\$(find -L '${unzip_dir}' -type f -name "*.fastq.gz" -o -name "*.fq.gz" | sort)

  pigz -dc \${CMPFQS} | cat - \${UNCMPFQS} | pigz -p ${task.cpus} > ${barcode}_concat.fq.gz
  """
}
