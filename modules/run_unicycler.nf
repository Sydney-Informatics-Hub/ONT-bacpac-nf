process unicycler_assembly {
    tag "ASSEMBLING GENOME WITH UNICYCLER: ${id}"
    container 'quay.io/biocontainers/unicycler:0.4.8--py38h8162308_3'
    //publishDir "${params.outDir}", mode: 'symlink'

    input:
    tuple val(sample), val(subset), path(trimmed_fq)

    output:
    tuple val(sample), val(subset), path("${id}_unicycler_assembly"), emit: unicycler_assembly
    tuple val(sample), val(subset), path("${id}_unicycler_assembly/assembly.gfa"), emit: unicycler_graph

    script:
    id = subset == null ? sample : "${sample}_${subset}"
    """
    unicycler \
        --long ${trimmed_fq} \\
        --threads ${task.cpus} \\
        --out ${id}_unicycler_assembly
    """
}
