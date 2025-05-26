#!/usr/bin/env nextflow

// To use DSL-2 will need to include this
nextflow.enable.dsl=2

// Import processes or subworkflows to be run in the workflow
include { estimate_genome_size } from '../subworkflows/estimate_genome_size'
include { autocycler_subsample } from '../modules/run_autocycler_subsample'
include { flye_assembly_subset } from '../modules/run_flye_subset'
include { unicycler_assembly_subset } from '../modules/run_unicycler_subset'
include { autocycler_compress } from '../modules/run_autocycler_compress'
include { autocycler_cluster } from '../modules/run_autocycler_cluster'
include { autocycler_trim } from '../modules/run_autocycler_trim'
include { autocycler_resolve } from '../modules/run_autocycler_resolve'
include { autocycler_combine } from '../modules/run_autocycler_combine'
include { autocycler_table } from '../modules/run_autocycler_table'


workflow autocycler {
    take:
    trimmed_fq

    main:
    // ESTIMATE GENOME SIZE
    estimate_genome_size(trimmed_fq)

    autocycler_inputs = trimmed_fq
        .join(estimate_genome_size.out.genome_size, by:0)

    // SUBSAMPLE FASTQ FILES
    autocycler_subsample(autocycler_inputs)

    // Expand the multiple FASTQs per barcode to one tuple per subset
    subsets = autocycler_subsample.out.subsets.transpose()

    // DE NOVO GENOME ASSEMBLIES
    flye_assembly_subset(subsets)
    unicycler_assembly_subset(subsets)

    all_assembly_dirs = flye_assembly_subset.out.flye_assembly
        .mix(unicycler_assembly_subset.out.unicycler_assembly)
        .groupTuple(by:0)

    autocycler_compress(all_assembly_dirs)

    autocycler_cluster(autocycler_compress.out.compressed)

    clusters_for_refinement = autocycler_cluster.out.pass_clusters
        .transpose()
        .map { barcode, cluster_dir ->
            def cluster_id = cluster_dir.baseName
            return [ barcode, cluster_id, cluster_dir ]
        }

    autocycler_trim(clusters_for_refinement)

    autocycler_resolve(autocycler_trim.out.trimmed_cluster)

    autocycler_resolve_out = autocycler_resolve.out.resolved_cluster
        .groupTuple(by:0)

    autocycler_combine_inputs = autocycler_cluster.out.cluster_out
        .join(autocycler_resolve_out, by:0)
        .map { barcode, autocycler_cluster_dir, cluster_ids, pass_cluster_dirs ->
            [ barcode, autocycler_cluster_dir, pass_cluster_dirs ]
        }

    autocycler_combine(autocycler_combine_inputs)

    autocycler_table(autocycler_combine.out.autocycler_out)

    consensus =
        autocycler_combine.out.autocycler_out
        .map { barcode, autocycler_dir ->
            def assembler = "consensus"
            def consensus_fa = autocycler_dir / "consensus_assembly.fasta"
            return [barcode, assembler, consensus_fa]
        }

    emit:
    polished_consensus_per_barcode = consensus
}