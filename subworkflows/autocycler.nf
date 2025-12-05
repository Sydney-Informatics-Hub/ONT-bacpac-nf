#!/usr/bin/env nextflow

// To use DSL-2 will need to include this
nextflow.enable.dsl=2

// Import processes or subworkflows to be run in the workflow
include { estimate_genome_size } from './estimate_genome_size'
include { denovo } from './denovo'
include { autocycler_subsample } from '../modules/run_autocycler_subsample'
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
    fastq  // [ barcode, fastq ]
    denovo_assemblies  // [ barcode, subset, assembler, assembly_dir ]
    plassembler_db

    main:
    // SUBSAMPLE FASTQ FILES - IF REQUESTED
    if (params.subsamples.toInteger() > 1) {
        // ESTIMATE GENOME SIZE
        estimate_genome_size(fastq)

        // PERFORM SUBSAMPLING
        autocycler_inputs = fastq
            .join(estimate_genome_size.out.genome_size, by:0)
        autocycler_subsample(autocycler_inputs)

        // Expand the multiple FASTQs per barcode to one tuple per subset and get the subsample ID
        subsets = autocycler_subsample.out.subsets
            .transpose()
            .map { barcode, fq -> [ barcode, fq.baseName.tokenize('_')[-1], fq ] }

        // DE NOVO GENOME ASSEMBLIES
        denovo(subsets, plassembler_db)

        all_assembly_dirs = denovo.out.assemblies
    } else {
        log.info "WARNING: Running autocycler without subsampling; this is not recommended unless subsampling is causing errors."
        all_assembly_dirs = denovo_assemblies
    }

    grouped_assembly_dirs = all_assembly_dirs
        .map { barcode, _subset, _assembler, assembly_dir -> [ barcode, assembly_dir ] }
        .groupTuple(by: 0)

    autocycler_compress(grouped_assembly_dirs)

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
        .map { barcode, autocycler_cluster_dir, _cluster_ids, pass_cluster_dirs ->
            [ barcode, autocycler_cluster_dir, pass_cluster_dirs ]
        }

    autocycler_combine(autocycler_combine_inputs)

    autocycler_table(autocycler_combine.out.autocycler_out)

    all_autocycler_metrics = autocycler_table.out.metrics
        .map { _barcode, tsv -> tsv }
        .collect()

    autocycler_table_mqc(all_autocycler_metrics)

    consensus =
        autocycler_combine.out.consensus_assembly
        .map { barcode, consensus_fa ->
            return [barcode, "consensus", consensus_fa]
        }

    consensus_to_polish = consensus
        .join(fastq)
        .map { barcode, _assembler, consensus_fa, input_fq -> [ barcode, input_fq, consensus_fa ]}
    
    medaka_polish_consensus(consensus_to_polish)

    polished_consensus =
        medaka_polish_consensus.out.polished_assembly
        .map { barcode, consensus_fa -> [ barcode, "consensus", consensus_fa ]}

    consensus_gfa =
        autocycler_combine.out.consensus_graph
        .map { barcode, consensus_gfa ->
            return [barcode, "consensus", consensus_gfa]
        }

    emit:
    polished_consensus_per_barcode = polished_consensus
    consensus_gfa_per_barcode = consensus_gfa
    metrics = autocycler_table_mqc.out.metrics
}