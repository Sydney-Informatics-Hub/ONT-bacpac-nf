process plassembler {
    tag "DETECTING PLASMIDS AND OTHER MOBILE ELEMENTS: ${id}"
    container 'quay.io/gbouras13/plassembler:1.6.2'
    publishDir "${params.outdir}/assemblies", mode: 'copy'

    input:
    tuple val(sample), val(subset), path(trimmed_fq), path(flye_assembly)
    path plassembler_db 

    output:
    tuple val(sample), val(subset), path("${id}_plassembler_assembly"), emit: plassembler_assembly, optional: true
    tuple val(sample), val(subset), path("${id}_plassembler_assembly/plassembler_plasmids.fasta"), emit: plassembler_fasta, optional: true
    tuple val(sample), val(subset), path("${id}_plassembler_assembly/plassembler_plasmids.gfa"), emit: plassembler_graph, optional: true
    tuple val(sample), val(subset), path("${id}_plassembler_logs"), emit: plassembler_logs, optional: true

    script:
    id = subset == null ? sample : "${sample}_${subset}"
    """
    plassembler long \\
        -d plasmid_db_plassembler \\
        -l ${trimmed_fq} \\
        --flye_assembly ${flye_assembly}/assembly.fasta \\
        --flye_info ${flye_assembly}/assembly_info.txt \\
        -o ${id}_plassembler_assembly \\
        -t ${task.cpus} -f
  
    # Check if the resulting .fasta file is empty
    if [ -s ${id}_plassembler_assembly/plassembler_plasmids.fasta ]; then
        echo "The .fasta file contains plasmid sequence. Proceeding with output."
    else
        echo "The .fasta file is empty, no plasmids detected. Removing from output."
        mv ${id}_plassembler_assembly ${id}_plassembler_logs
    fi
    """
}
