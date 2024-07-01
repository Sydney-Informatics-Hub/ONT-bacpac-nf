process concat_fastqs {
    tag "CONCATENATING FASTQS: ${barcode}"

    input:
    tuple val(barcode), path(unzip_dir)

    output:
    tuple val(barcode), path("*_concat.fq.gz"), emit: concat_fq

    script: // This process runs ../bin/concatfq.py 
    """
    concatfq.py \\
      ${unzip_dir}
    """
}
