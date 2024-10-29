process concat_fastas {
    tag "${barcode}"

    input:
    tuple val(barcode), path(fasta_files)

    output:
    tuple val(barcode), path("${barcode}_combined.fasta")

    script:
    """
    cat $fasta_files > ${barcode}_combined.fasta
    """
}
