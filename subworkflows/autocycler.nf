#!/usr/bin/env nextflow

// To use DSL-2 will need to include this
nextflow.enable.dsl=2

// Import processes or subworkflows to be run in the workflow
include { estimate_genome_size } from '../subworkflows/estimate_genome_size'
include { autocycler_subsample } from '../modules/run_autocycler_subsample'
include { flye_assembly_subset } from '../modules/run_flye_subset'
include { unicycler_assembly_subset } from '../modules/run_unicycler_subset'
include { raven_assembly_subset } from '../modules/run_raven_subset'
include { autocycler_compress } from '../modules/run_autocycler_compress'
include { autocycler_cluster } from '../modules/run_autocycler_cluster'
include { autocycler_trim } from '../modules/run_autocycler_trim'
include { autocycler_resolve } from '../modules/run_autocycler_resolve'
include { autocycler_combine } from '../modules/run_autocycler_combine'
include { autocycler_table } from '../modules/run_autocycler_table'
include { autocycler_table_mqc } from '../modules/run_autocycler_table_mqc'
include { medaka_polish_consensus } from '../modules/run_medaka_polish_consensus'


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
    raven_assembly_subset(subsets)
    // ADD CALLS TO NEW SUBSET ASSEMBLERS HERE

    // MIX ASSEMBLIES TOGETHER
    mixed_assemblies = 
        unicycler_assembly_subset.out.unicycler_assembly
        .mix(flye_assembly_subset.out.flye_assembly)
        .mix(raven_assembly_subset.out.raven_assembly)
        // MIX IN NEW ASSEMBLERS HERE

    all_assembly_dirs = mixed_assemblies
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

    all_autocycler_metrics = autocycler_table.out.metrics
        .map { barcode, tsv -> tsv }
        .collect()

    autocycler_table_mqc(all_autocycler_metrics)

    consensus =
        autocycler_combine.out.autocycler_out
        .map { barcode, autocycler_dir ->
            def assembler = "consensus"
            def consensus_fa = autocycler_dir / "consensus_assembly.fasta"
            return [barcode, assembler, consensus_fa]
        }

    consensus_to_polish = consensus
        .join(trimmed_fq)
        .map { barcode, _assembler, consensus_fa, input_fq -> [ barcode, input_fq, consensus_fa ]}
    
    medaka_polish_consensus(consensus_to_polish)

    polished_consensus =
        medaka_polish_consensus.out.polished_assembly
        .map { barcode, consensus_fa -> [ barcode, "consensus", consensus_fa ]}

    consensus_gfa =
        autocycler_combine.out.autocycler_out
        .map { barcode, autocycler_dir ->
            def assembler = "consensus"
            def consensus_gfa = autocycler_dir / "consensus_assembly.gfa"
            return [barcode, assembler, consensus_gfa]
        }

    emit:
    polished_consensus_per_barcode = polished_consensus
    consensus_gfa_per_barcode = consensus_gfa
    metrics = autocycler_table_mqc.out.metrics
}