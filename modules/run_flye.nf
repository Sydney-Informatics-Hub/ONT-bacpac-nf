process flye_assembly {
    tag "ASSEMBLING GENOME WITH FLYE: ${id}"
    container 'quay.io/biocontainers/flye:2.9.3--py310h2b6aa90_0'

    input:
    tuple val(barcode), val(subset), path(trimmed_fq)

    output:
    tuple val(barcode), val(subset), path("${id}_flye_assembly"), emit: flye_assembly
    tuple val(barcode), val(subset), path("${id}_flye_assembly/assembly_graph.gfa"), emit: flye_graph

    script:
    id = subset == null ? barcode : "${barcode}_${subset}"
    """
    flye \\
        --nano-hq ${trimmed_fq} \\
        --threads ${task.cpus} \\
        --out-dir ${id}_flye_assembly
    """
}
