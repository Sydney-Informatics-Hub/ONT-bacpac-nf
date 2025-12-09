process plassembler {
    tag "DETECTING PLASMIDS AND OTHER MOBILE ELEMENTS: ${id}"
    container 'quay.io/gbouras13/plassembler:1.6.2'
    publishDir "${params.outdir}/assemblies", mode: 'copy'

    input:
    tuple val(barcode), val(subset), path(trimmed_fq), path(flye_assembly), val(chrom_length)
    path plassembler_db 

    output:
    tuple val(barcode), val(subset), path("${id}_plassembler_assembly"), emit: plassembler_assembly, optional: true
    tuple val(barcode), val(subset), path("${id}_plassembler_assembly/plassembler_plasmids.fasta"), emit: plassembler_fasta, optional: true
    tuple val(barcode), val(subset), path("${id}_plassembler_assembly/plassembler_plasmids.gfa"), emit: plassembler_graph, optional: true
    tuple val(barcode), val(subset), path("${id}_plassembler_logs"), emit: plassembler_logs, optional: true

    script:
    id = subset == null ? barcode : "${barcode}_${subset}"
    min_chrom_length_param = chrom_length && chrom_length.toString().isInteger() ? "-c ${chrom_length}" : ""
    """
    set +e
    plassembler long \\
        -d plasmid_db_plassembler \\
        -l ${trimmed_fq} \\
        --flye_assembly ${flye_assembly}/assembly.fasta \\
        --flye_info ${flye_assembly}/assembly_info.txt \\
        ${min_chrom_length_param} \\
        -o ${id}_plassembler_assembly \\
        -t ${task.cpus} -f 2> _plassembler.stderr

    EXITCODE="\$?"

    cat _plassembler.stderr >&2
    NOCHROM=\$(grep " ERROR " _plassembler.stderr | tail -n 1 | grep -c "No chromosome was identified")

    set -e

    if [ "\$EXITCODE" == "1" ] && [ "\$NOCHROM" == "1" ]; then
        echo "WARN: Plassembler didn't find any chromosomes. Ignoring."
    elif [ ! "\$EXITCODE" == "0" ]; then
        echo "ERROR: Plassembler failed. Exiting."
        exit 1
    fi

    # Check if the resulting .fasta file is empty
    if [ -s ${id}_plassembler_assembly/plassembler_plasmids.fasta ]; then
        echo "The .fasta file contains plasmid sequence. Proceeding with output."
    else
        echo "The .fasta file is empty, no plasmids detected. Removing from output."
        mv ${id}_plassembler_assembly ${id}_plassembler_logs
    fi
    """
}
