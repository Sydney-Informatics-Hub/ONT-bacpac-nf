#!/usr/bin/env nextflow

// To use DSL-2 will need to include this
nextflow.enable.dsl=2

// Import processes or subworkflows to be run in the workflow
include { flye_assembly } from '../modules/run_flye'
include { unicycler_assembly } from '../modules/run_unicycler'
include { plassembler } from '../modules/run_plassembler'

workflow denovo {
    take:
    fastq  // [ sample, subset, fastq ]; subset can be null
    plassembler_db

    main:
    // Get user-chosen assemblers
    def selected_assemblers = params.assemblers.tokenize(',')

    // Determine which assemblers to run
    // Flye always runs because we want it for plassembler
    flye_input = fastq
    // Unicycler is optional
    unicycler_input = fastq
        .filter { selected_assemblers.contains('unicycler') }

    // Run long read assemblers
    flye_assembly(flye_input)
    unicycler_assembly(unicycler_input)

    // Run plasmid assembly
    plassembler_input = fastq
        .join(flye_assembly.out.flye_assembly, by: [0, 1])
    plassembler(plassembler_input, plassembler_db)

    // Gather assemblies
    flye_assemblies = flye_assembly.out.flye_assembly
        .map { sample, subset, assembly_dir -> [ sample, subset, 'flye', assembly_dir ] }
    unicycler_assemblies = unicycler_assembly.out.unicycler_assembly
        .map { sample, subset, assembly_dir -> [ sample, subset, 'unicycler', assembly_dir ] }
    plassembler_assemblies = plassembler.out.plassembler_assembly
        .map { sample, subset, assembly_dir -> [ sample, subset, 'plassembler', assembly_dir ] }

    all_assemblies = flye_assemblies
        .mix(unicycler_assemblies)
        .mix(plassembler_assemblies)

    // Gather graphs
    flye_graphs = flye_assembly.out.flye_graph
        .map { sample, subset, assembly_graph -> [ sample, subset, 'flye', assembly_graph ] }
    unicycler_graphs = unicycler_assembly.out.unicycler_graph
        .map { sample, subset, assembly_graph -> [ sample, subset, 'unicycler', assembly_graph ] }
    plassembler_graphs = plassembler.out.plassembler_graph
        .map { sample, subset, assembly_graph -> [ sample, subset, 'plassembler', assembly_graph ] }

    all_graphs = flye_graphs
        .mix(unicycler_graphs)
        .mix(plassembler_graphs)

    emit:
    assemblies = all_assemblies
    graphs = all_graphs
    plassembler_fasta = plassembler.out.plassembler_fasta
}