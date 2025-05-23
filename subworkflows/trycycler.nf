#!/usr/bin/env nextflow

// To use DSL-2 will need to include this
nextflow.enable.dsl=2

// Import processes or subworkflows to be run in the workflow
include { trycycler_subsample } from '../modules/run_trycycler_subsample'
include { flye_assembly_subset } from '../modules/run_flye_subset'
include { unicycler_assembly_subset } from '../modules/run_unicycler_subset'
include { trycycler_cluster } from '../modules/run_trycycler_cluster'
include { trycycler_cluster_subset } from '../modules/run_trycycler_cluster_subset'
include { classify_trycycler } from '../modules/run_trycycler_classify'
include { trycycler_reconcile } from '../modules/run_trycycler_reconcile'
include { trycycler_msa } from '../modules/run_trycycler_msa'
include { trycycler_partition } from '../modules/run_trycycler_partition'
include { trycycler_consensus} from '../modules/run_trycycler_consensus'
include { medaka_polish_consensus } from '../modules/run_medaka_polish_consensus'
include { concat_fastas } from '../modules/concat_fa'


workflow trycycler {
    take:
    trimmed_fq
    trycycler_assemblies

    main:
    if (params.subsamples.toInteger() > 1) {

        // Subsampling to be performed
        // SUBSAMPLE FASTQ FILES
        trycycler_subsample(trimmed_fq)

        // Expand the multiple FASTQs per barcode to one tuple per subset
        subsets = trycycler_subsample.out.subsets.transpose()

        // DE NOVO GENOME ASSEMBLIES
        // We need to re-run the assemblies on each subset
        flye_assembly_subset(subsets)
        unicycler_assembly_subset(subsets)

        /*
        * CONSENSUS ASSEMBLY PRE-PROCESSING
        * 
        * Trycycler requires >= 3 contigs to run. Use the in-built .countFasta()
        * operator to count the total number of contigs assembled for each barcode.
        *
        * If additional assemblers/read subsets/replicates are added, ensure it 
        * is added here.
        */
        num_contigs_per_barcode =
            unicycler_assembly_subset.out.unicycler_assembly
            .mix(flye_assembly_subset.out.flye_assembly)
            .map { barcode, assembly_dir ->
                // Count num contigs per assembly
                def fa = assembly_dir + "/assembly.fasta"
                def ncontigs = fa.countFasta()
                return [barcode, ncontigs]
            }
            .groupTuple()
            .map { barcode, ncontigs ->
                // Add total contigs across assemblies
                def total_contigs = ncontigs.inject(0, { result, x -> result + x.toInteger() })
                return [barcode, total_contigs]
            }

        unicycler_assembly_subset_grouped = unicycler_assembly_subset.out.unicycler_assembly
            .groupTuple()
        flye_assembly_subset_grouped = flye_assembly_subset.out.flye_assembly
            .groupTuple()
        denovo_assemblies =
            unicycler_assembly_subset_grouped
            .join(flye_assembly_subset_grouped, by:0)
            .join(trimmed_fq, by:0)
            .join(num_contigs_per_barcode, by:0)

        denovo_assembly_contigs =
            denovo_assemblies
            .branch { barcode, unicycler, flye, trimmed_fastq, num_contigs ->
                run_trycycler: num_contigs >= 3
                skip_trycycler: num_contigs < 3
            }

        // RUN TRYCYCLER (CONSENSUS ASSEMBLY) IF SUFFICIENT # CONTIGS
        // TRYCYCLER: Cluster contigs
        trycycler_cluster_subset(denovo_assembly_contigs.run_trycycler)

        barcode_cluster_sizes =
            // trycycler_cluster filters out small contigs (default < 5000nt) and can
            // result in < 2 contigs here again. Use the same branching logic to avoid
            // < 2 contig errors.
            trycycler_cluster_subset.out.phylip
            .map { barcode, contigs_phylip ->
                def phylip_lines = contigs_phylip.text.readLines().size - 1 // exclude header
                return [barcode, phylip_lines]
            }
            .branch { barcode, phylip_lines ->
                run_trycycler: phylip_lines >= 3
                skip_trycycler: phylip_lines < 3
                // create a channel from skip_trycycler if failed barcodes need to be reported/used
            }

        // TRYCYCLER: Classify clusters
        clusters_to_classify =
            // Add path to clusters with sufficient contigs
            trycycler_cluster_subset.out.clusters
            .join(barcode_cluster_sizes.run_trycycler)

    } else {

        // No subsampling
        // Start by clustering the existing assemblies
        trycycler_cluster(trycycler_assemblies)

        // trycycler_cluster filters out small contigs (default < 5000nt) and can
        // result in < 2 contigs here.
        // Use branching logic to avoid < 2 contig errors.
        barcode_cluster_sizes =
            trycycler_cluster.out.phylip
            .map { barcode, contigs_phylip ->
                def phylip_lines = contigs_phylip.text.readLines().size - 1 // exclude header
                return [barcode, phylip_lines]
            }
            .branch { barcode, phylip_lines ->
                run_trycycler: phylip_lines >= 3
                skip_trycycler: phylip_lines < 3
            }

        // TRYCYCLER: Classify clusters
        clusters_to_classify =
            // Add path to clusters with sufficient contigs
            trycycler_cluster.out.clusters
            .join(barcode_cluster_sizes.run_trycycler)

    }

    classify_trycycler(clusters_to_classify)

    // TRYCYCLER: Reconcile contigs
    clusters_to_reconcile_flat = 
        classify_trycycler.out.clusters_to_reconcile
        .join(trimmed_fq, by: 0)
        // from [barcode, [pathA, pathB], ...]
        // to [barcode, pathA, ...]; [barcode, pathB, ...]
        .transpose()

    trycycler_reconcile(clusters_to_reconcile_flat)

    reconciled_cluster_dirs = 
        trycycler_reconcile.out.reconciled_seqs // successfully reconciled
        .map { barcode, seq ->
            // drops the last part of the path (reconciled_seqs file) as trycycler
            // searches the parent dir for it
            Path cluster_dir = seq.getParent()
            return [barcode, cluster_dir] 
        }
    
    // TRYCYCLER: Align
    trycycler_msa(reconciled_cluster_dirs)

    // TRYCYCLER: Partitioning reads
    clusters_to_partition =
        trycycler_msa.out.results_dir
        .groupTuple()
        .join(trimmed_fq)

    trycycler_partition(clusters_to_partition)

    // TRYCYCLER: Generate consensus assemblies  
    clusters_for_consensus =
        trycycler_partition.out.partitioned_reads
        .transpose() // "ungroup" tuple
        .map { barcode, reads ->
            // Get directories of successfully partitioned reads
            Path cluster_dir = reads.getParent()
            return [barcode, cluster_dir]
        }

    trycycler_consensus(clusters_for_consensus)

    // MEDAKA: Polish consensus assembly
    consensus_dir = 
        // Get parent dir for assembly
        trycycler_consensus.out.cluster_assembly
        .map { barcode, assembly ->
            Path assembly_dir = assembly.getParent()
            return [barcode, assembly_dir]
        }

    medaka_polish_consensus(consensus_dir)

    // CAT: Combine polished clusters consensus assemblies into a single fasta
    polished_clusters = 
        medaka_polish_consensus.out.cluster_assembly
        .groupTuple()
        .map { barcode, fastas ->
            // Need to avoid filename collisions with consensus.fasta files
            // by renaming them
            def indexed_fas = 
                fastas.withIndex()
                .collect { fa, idx ->
                    def new_fa = fa.getParent() / "consensus_${idx}.fasta"
                    fa.copyTo(new_fa)
                    return new_fa
                }
            return [barcode, indexed_fas]
        }
    
    concat_fastas(polished_clusters)

    consensus =
        concat_fastas.out
        .map { barcode, consensus_fa ->
            String assembler = "consensus"
            return [barcode, assembler, consensus_fa]
        }

    emit:
    polished_consensus_per_barcode = consensus
}