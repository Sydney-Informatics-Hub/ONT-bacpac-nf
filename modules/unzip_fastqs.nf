process unzip_fastqs {
  tag "UNZIP INPUT FASTQs: ${unzip_id}"
  container 'python:3.8'

  input:
	tuple val(barcode), val(sample), val(batch), path(zipped_fqs)
    
  output:
  tuple val(barcode), val(sample), val(batch), path("${unzip_id}") , emit: unzipped

  script:
  def batch_id = batch ? ".${batch}" : ""
  unzip_id = "${barcode}.${sample}${batch_id}"
  """
  mkdir ${unzip_id}
  mkdir tmp
	unzip -d tmp ${zipped_fqs}
  mv \$(find tmp -type f -name "*.fastq" -o -name "*.fq" -o -name "*.fastq.gz" -o -name "*.fq.gz") ${unzip_id}/
  """
}
