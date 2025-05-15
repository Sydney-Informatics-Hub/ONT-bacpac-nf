process unzip_fastqs {
  tag "UNZIP INPUT FASTQs: ${barcode}"
  container 'python:3.8'

  input:
	tuple val(barcode), path(zipped_fqs)
    
  output:
  tuple val(barcode), path("${barcode}") , emit: unzipped

  script:
  """
  mkdir ${barcode}
  mkdir tmp
	unzip -d tmp ${zipped_fqs}
  mv \$(find tmp -type f -name "*.fastq" -o -name "*.fq" -o -name "*.fastq.gz" -o -name "*.fq.gz") ${barcode}/
  """
}
