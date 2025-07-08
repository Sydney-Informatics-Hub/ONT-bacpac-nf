#!/usr/bin/env nextflow

// To use DSL-2 will need to include this
nextflow.enable.dsl=2

// Import processes or subworkflows to be run in the workflow
include { unzip_fastqs } from './modules/unzip_fastqs'
include { concat_fastas } from './modules/concat_fa'
include { concat_fastqs } from './modules/run_pigz'
include { porechop } from './modules/run_porechop' 
include { pycoqc_summary } from './modules/run_pycoqc'
include { nanoplot_summary } from './modules/run_nanoplot'
include { get_ncbi } from './modules/get_ncbi'
include { get_busco } from './modules/get_busco'
include { get_amrfinderplus } from './modules/get_amrfinderplus'
include { get_plassembler } from './modules/get_plassembler'
include { get_kraken2 } from './modules/get_kraken2'
include { get_bakta } from './modules/get_bakta'
include { kraken2 } from './modules/run_kraken2'
include { flye_assembly } from './modules/run_flye'
include { unicycler_assembly } from './modules/run_unicycler'
include { trycycler } from './subworkflows/trycycler'
include { autocycler } from './subworkflows/autocycler'
include { bandage } from './modules/run_bandage'
include { generate_bandage_report } from './modules/generate_bandage_report'
include { select_assembly } from './modules/select_assembly'
include { medaka_polish_denovo } from './modules/run_medaka_polish_denovo'
include { plassembler } from './modules/run_plassembler'
include { bakta_annotation_plasmids } from './modules/run_bakta_annotation_plasmids'
include { busco_annotation_plasmids } from './modules/run_busco_annotation_plasmids'
include { quast_qc_chromosomes } from './modules/run_quast_qc_chromosomes'
include { bakta_annotation_chromosomes } from './modules/run_bakta_annotation_chromosomes'
include { busco_qc_chromosomes } from './modules/run_busco_qc_chromosomes'
include { abricateVFDB_annotation_chromosomes } from './modules/run_abricateVFDB_annotation_chromosomes'
include { abricateVFDB_annotation_reference } from './modules/run_abricateVFDB_annotation_reference'
include { amrfinderplus_annotation_chromosomes } from './modules/run_amrfinderplus_annotation_chromosomes'
include { create_samplesheet_for_processed } from './modules/create_samplesheet_for_processed'
include { create_phylogeny_tree_related_files } from './modules/create_phylogeny_tree_related_files'
include { run_orthofinder } from './modules/run_orthofinder'
include { amrfinderplus_annotation_reference } from './modules/run_amrfinderplus_annotation_reference'
include { generate_amrfinderplus_gene_matrix } from './modules/generate_amrfinderplus_gene_matrix'
include { generate_abricate_gene_matrix } from './modules/generate_abricate_gene_matrix'
include { create_phylogeny_And_Heatmap_image } from './modules/create_phylogeny_And_Heatmap_image'
include { generate_consensus_warnings } from './modules/generate_consensus_warnings'
include { multiqc_report } from './modules/run_multiqc'
include { multiqc_results_report } from './modules/run_multiqc_results'

// Print a header for your pipeline 
log.info """\

=======================================================================================
O N T - B A C P A C K - nf 
=======================================================================================

Created by TODO NAME 
Find documentation @ TODO INSERT LINK
Cite this pipeline @ TODO INSERT DOI

=======================================================================================
Workflow run parameters 
=======================================================================================
inputDir           : ${params.input_directory} 
samplesheet        : ${params.samplesheet}
sequencing_summary : ${params.sequencing_summary}
results            : ${params.outdir}
workDir            : ${workflow.workDir}
profiles           : ${workflow.profile}
=======================================================================================

"""

/// Help function 
// This is an example of how to set out the help function that 
// will be run if run command is incorrect or missing. 

def helpMessage() {
    log.info"""
  Usage:  nextflow run main.nf --input_directory <path to directory> 

  Required Arguments:

  --input_directory   Specify full path and name of directory OR
  --samplesheet       Spectify full path and name of samplesheet csv. 

  Optional Arguments:

  --outdir              Specify path to output directory.
  --multiqc_config      Configure multiqc reports.
  --sequencing_summary	Sequencing summary log from sequencer.
	
""".stripIndent()
}

// Define workflow structure. Include some input/runtime tests here.
// See https://www.nextflow.io/docs/latest/dsl2.html?highlight=workflow#workflow
workflow {

  if ( params.help || (!params.input_directory && !params.samplesheet) || !params.sequencing_summary) {   
  // Invoke the help function above and exit
    helpMessage()
    System.exit(1)
    // consider adding some extra contigencies here.
    // could validate path of all input files in list?
    // could validate indexes for reference exist?

  // If none of the above are a problem, then run the workflow
  } else {

    // DOWNLOAD DATABASES  
    get_amrfinderplus()
    amrfinderplus_db = get_amrfinderplus.out.amrfinderplus_db

    get_plassembler()
    plassembler_db = get_plassembler.out.plassembler_db

    get_ncbi()
    //TODO revise the requirement for this process. We'll need the lookup for the tree, but likely not for select_assembly 

    get_busco()
    busco_db = get_busco.out.busco_db
    
    // Only download kraken2 if existing db not already provided 
    if (!params.kraken2_db){
      get_kraken2()
      kraken2_db = get_kraken2.out.kraken2_db

    } else { 
      log.info "FYI: USING EXISTING KRAKEN2 DATABASE ${params.kraken2_db}"
      kraken2_db = params.kraken2_db
    }

    // Only download bakta if existing db not already provided 
    if (!params.bakta_db){
      get_bakta()

    } else { 
      log.info "FYI: USING EXISTING BAKTA DATABASE ${params.bakta_db}"
    }

    // Get input FASTQs
    if (params.input_directory){
      // VALIDATE INPUT DIRECTORY 
      log.info "USING INPUT DIRECTORY `${params.input_directory}`"
      zipped_fqs = Channel.fromPath(params.input_directory + '/*.zip')
        .map { f -> [ f.baseName, f ] }
    } else {
      // VALIDATE SAMPLESHEET
      log.info "READING ZIPPED FASTQS FROM SAMPLESHEET `${params.samplesheet}`"
      zipped_fqs = Channel.fromPath(params.samplesheet)
        .splitCsv( header: true )
        .map { row -> [ row.barcode, file(row.file_path) ] }
    }

    unzipped_fq_dirs = unzip_fastqs(zipped_fqs)
  }

  // CONCATENATE FQS PER SAMPLE
  concat_fastqs(unzipped_fq_dirs)

  // QC SUMMARY OF RAW INPUTS 
  // INPUT FILE GENERATED BY THE ONT MACHINE 
  sequencing_summary = params.sequencing_summary

  nanoplot_summary(sequencing_summary)
  pycoqc_summary(sequencing_summary)
  
  // PORECHOP NANOPORE ADAPTERS 
  porechop(concat_fastqs.out.concat_fq)

  // SCREEN FOR CONTAMINANTS 
  kraken2(porechop.out.trimmed_fq, kraken2_db)

  // DE NOVO GENOME ASSEMBLIES
  flye_assembly(porechop.out.trimmed_fq)
  unicycler_assembly(porechop.out.trimmed_fq)

  // DETECT PLASMIDS AND OTHER MOBILE ELEMENTS 
  plassembler_in = porechop.out.trimmed_fq
                  .join(flye_assembly.out.flye_assembly, by: 0)
                  .map { barcode, trimmed_fq, flye_assembly -> tuple(barcode, trimmed_fq, flye_assembly) }
                  
  plassembler(plassembler_in, get_plassembler.out.plassembler_db)

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
    unicycler_assembly.out.unicycler_assembly
    .mix(flye_assembly.out.flye_assembly)
    .map { barcode, assembly_dir ->
        // Count num contigs per assembly
        def fa = assembly_dir + "/assembly.fasta"
        def ncontigs = fa.countFasta()
        return [barcode, ncontigs]
    }
    .groupTuple()
    .map { barcode, ncontigs ->
        // Add total contigs across assemblies
        def total_contigs = ncontigs[0].toInteger() + ncontigs[1].toInteger()
        return [barcode, total_contigs]
    }

  denovo_assemblies =
    unicycler_assembly.out.unicycler_assembly
    .join(flye_assembly.out.flye_assembly, by:0)
    .join(porechop.out.trimmed_fq, by:0)
    .join(num_contigs_per_barcode, by:0)

  denovo_assembly_contigs =
    denovo_assemblies
    .branch { barcode, unicycler, flye, trimmed_fq, num_contigs ->
        run_trycycler: num_contigs >= 3
        skip_trycycler: num_contigs < 3
    }

  trycycler_skipped_barcodes =
    // barcodes with insufficient contigs for trycycler
    // TODO: Remove this when select_assembly is revised.
    // denovo_assemblies can be passed directly when ready.
    denovo_assembly_contigs.skip_trycycler
    .map { 
        barcode, unicycler_assembly, flye_assembly, trimmed_fq, num_contigs -> barcode
    }
    .collect()

  if (params.consensus_method == 'trycycler') {
    // RUN TRYCYCLER (CONSENSUS ASSEMBLY) IF SUFFICIENT # CONTIGS
    trycycler(porechop.out.trimmed_fq, denovo_assembly_contigs.run_trycycler)

    polished_consensus_per_barcode = trycycler.out.polished_consensus_per_barcode
    consensus_gfa_per_barcode = Channel.empty()  // To ensure that consensus_gfa_per_barcode exists
    autocycler_metrics = Channel.empty()  // To ensure that autocycler_metrics exists
  } else if (params.consensus_method == 'autocycler') {
    // RUN AUTOCYCLER

    // First, check that params.subsamples > 1
    if (!(params.subsamples.toInteger() > 1)) {
      log.info "Error: autocycler must be run with > 1 subsamples"
      System.exit(1)
    }
    
    autocycler(porechop.out.trimmed_fq)

    polished_consensus_per_barcode = autocycler.out.polished_consensus_per_barcode
    consensus_gfa_per_barcode = autocycler.out.consensus_gfa_per_barcode
    autocycler_metrics = autocycler.out.metrics
  } else {
    error 'Invalid value for `consensus_method`: ' + params.consensus_method
  }

  // Identify failed barcodes and create a list of their names
  consensus_failures = concat_fastqs.out.concat_fq
    .map { barcode, _fq -> barcode }
    .unique()
    .join(polished_consensus_per_barcode, remainder: true)
    .filter { _barcode, _assembler, fa -> !fa }
    .map { barcode, _assembler, _fa -> barcode }
    .collect()

  // Generate MultiQC-ready YAML file of failed barcodes
  generate_consensus_warnings(consensus_failures, params.consensus_method)
  consensus_warnings = generate_consensus_warnings.out.mqc_yaml
    .ifEmpty([])

  // RUN BANDAGE ON AUTOCYCLER OUTPUTS
  // DE NOVO ASSEMBLY GRAPHS
  // AND PLASEMBLER GRAPHS
  plassembler_graphs = plassembler.out.plassembler_gfa
    .map { barcode, graph ->
      [ barcode, "plassembler", graph ]
    }
  graphs_for_bandage =
    unicycler_assembly.out.unicycler_graph
    .mix(flye_assembly.out.flye_graph)
    .mix(consensus_gfa_per_barcode)
    .mix(plassembler_graphs)
    .filter { barcode, assembly, graph ->
      graph.size() > 0
    }

  bandage(graphs_for_bandage)

  // Generate MultiQC-ready Bandage report
  all_bandage_plots = bandage.out.bandage_plot
    .map { barcode, assembly, plot -> plot }
    .collect()
  generate_bandage_report(all_bandage_plots)

  // MEDAKA: POLISH DE NOVO ASSEMBLIES
  unpolished_denovo_assemblies =
    unicycler_assembly.out.unicycler_assembly
    .mix(flye_assembly.out.flye_assembly)
    .map { barcode, assembly_dir -> 
        // Get the assembler name by parsing the publishDir path.
        // A better way to do this is output i.e. val(assembler_name) in the
        // assembly processes but will required more changes
        String assembler_name = assembly_dir.toString().tokenize("_")[-2]
        return [barcode, assembler_name, assembly_dir] 
    }
    .combine(porechop.out.trimmed_fq, by: 0)

  medaka_polish_denovo(unpolished_denovo_assemblies)

  // ASSEMBLY QC
  all_polished = polished_consensus_per_barcode
    .mix(medaka_polish_denovo.out.assembly)

  // TODO: probably better to collect all per-barcode assemblies in one quast
  // run to void a parsing/merging step
  quast_qc_chromosomes(all_polished)
  busco_qc_chromosomes(all_polished, get_busco.out.busco_db)
  
  // SELECT "BEST" ASSEMBLY
  // TODO: Discuss better approaches. Currently selects the best assembly per
  // barcode by most Complete BUSCO % 
  barcode_busco_jsons =
    // Gather all jsons for each barcode
    busco_qc_chromosomes.out.json_summary
    .groupTuple()

  select_assembly(barcode_busco_jsons)
  
  best_chr_assembly = 
    select_assembly.out
    .map { barcode, txt ->
      // best assembly stored in txt file for pipeline caching
      String best = txt.splitText()[0].strip()
      return [barcode, best]
    }
    .join(all_polished, by: [0, 1])

  // ANNOTATE THE BEST CHROMOSOMAL ASSEMBLY PER-BARCODE
  // BAKTA: Annotate gene features
  bakta_annotation_chromosomes(best_chr_assembly, get_bakta.out.bakta_db)

  // ABRICATE: Annotate VFDB genes
  abricateVFDB_annotation_chromosomes(best_chr_assembly)

  // AMRFINDERPLUS: Annotate AMR genes
  amrfinderplus_annotation_chromosomes(
    bakta_annotation_chromosomes.out.faa,
    get_amrfinderplus.out.amrfinderplus_db
  )

  // CREATE FILES FOR PHYLOGENETIC TREE BUILDING
  // Collect all the output (annotation) reports required for tree building
  kraken2_reports =
    // Collect all k2 reports and drop barcodes
    kraken2.out
    .map { barcode, k2_report -> k2_report }
    .collect()

  bakta_results_dirs = 
    // TODO: Currently takes dir as input, amend the phylo building .py file
    // to take direct inputs
    bakta_annotation_chromosomes.out.txt
    .map { barcode, assembler, txt -> 
        Path dir = txt.getParent()
        return dir
    } 
    .collect()

  create_phylogeny_tree_related_files(
    get_ncbi.out.assembly_summary_refseq,
    kraken2_reports,
    bakta_results_dirs
  )

  // ORTHOFINDER: Infer phylogeny using orthologous genes
  phylogeny_in = create_phylogeny_tree_related_files.out.phylogeny_folder
  run_orthofinder(phylogeny_in)

  // ANNOTATE REFERENCE STRAINS
  // AMRFINDERPLUS: Annotate AMR genes
  amrfinderplus_annotation_reference(
    phylogeny_in,
    get_amrfinderplus.out.amrfinderplus_db
  )

  // ABRICATE: Annotate VFDB genes
  abricateVFDB_annotation_reference(phylogeny_in) 

  // PYTHON: Generate gene matrix for phylogeny-AMR heatmap (AMRFINDERPLUS)
  amrfinderplus_chr_reports =
    amrfinderplus_annotation_chromosomes.out.report
    .map { barcode, assembler, report -> report }
    .collect()

  barcode_species_table = create_phylogeny_tree_related_files.out.barcode_species_table

  generate_amrfinderplus_gene_matrix(
    amrfinderplus_chr_reports,
    amrfinderplus_annotation_reference.out.amrfinderplus_annotations,
    barcode_species_table
  )

  // PYTHON: Generate gene matrix for phylogeny-AMR heatmap (ABRICATE)
  abricate_chr_reports = 
    abricateVFDB_annotation_chromosomes.out.report
    .map { barcode, report -> report }
    .collect()

  generate_abricate_gene_matrix(
    abricate_chr_reports,
    abricateVFDB_annotation_reference.out.abricate_annotations,
    barcode_species_table
  )

  // R: Plot phylogeny and heatmap
  create_phylogeny_And_Heatmap_image(
    run_orthofinder.out.rooted_tree,
    generate_amrfinderplus_gene_matrix.out.amrfinderplus_gene_matrix,
    generate_abricate_gene_matrix.out.abricate_gene_matrix
  )

  // BAKTA: Annotate plasmid gene features
  bakta_annotation_plasmids(plassembler.out.plassembler_fasta, get_bakta.out.bakta_db)

  // SUMMARISE RUN WITH MULTIQC REPORT
  // Ensure all necessary inputs are available for MultiQC, even if some are empty
  nanoplot_required_for_multiqc = nanoplot_summary.out.nanoplot_summary.ifEmpty([])
  pycoqc_required_for_multiqc = pycoqc_summary.out.pycoqc_json.ifEmpty([])

  kraken2_required_for_multiqc = 
    kraken2.out.kraken2_screen
    .map { it[1] }
    .collect()
    .ifEmpty([])

  quast_required_for_multiqc = 
    quast_qc_chromosomes.out.tsv
    .map { barcode, assembler, tsv -> tsv }
    .collect()

  bakta_required_for_multiqc =
    bakta_annotation_chromosomes.out.txt
    .map { barcode, assembler, txt -> txt }
    .collect()

  busco_required_for_multiqc =
    busco_qc_chromosomes.out.txt_summary
    .map { barcode, assembler, txt -> txt }
    .collect()

  bakta_plasmids_required_for_multiqc = 
    bakta_annotation_plasmids.out.bakta_annotations
    .map { it[1] }
    .collect()
    .ifEmpty([])

  phylogeny_heatmap_plot_required_for_multiqc = 
    create_phylogeny_And_Heatmap_image.out.combined_plot_mqc
    .ifEmpty([])

  bandage_report = generate_bandage_report.out.bandage_report

  autocycler_metrics_for_mqc = autocycler_metrics
    .ifEmpty([])

  multiqc_config = params.multiqc_config
  multiqc_results_config = params.multiqc_results_config

  // Run MultiQC with the gathered inputs
  // QC report
  multiqc_report(
    pycoqc_required_for_multiqc,
    nanoplot_required_for_multiqc,
    multiqc_config,
    quast_required_for_multiqc,
    busco_required_for_multiqc,
    bandage_report,
    autocycler_metrics_for_mqc,
    consensus_warnings
  )
  // Results report
  multiqc_results_report(
    multiqc_results_config,
    kraken2_required_for_multiqc,
    bakta_required_for_multiqc,
    bakta_plasmids_required_for_multiqc,
    phylogeny_heatmap_plot_required_for_multiqc,
    consensus_warnings
  )
  // Print workflow execution summary 
  workflow.onComplete = {
    def summary = """
    =======================================================================================
    Workflow execution summary
    =======================================================================================

    Duration    : ${workflow.duration}
    Success     : ${workflow.success}
    workDir     : ${workflow.workDir}
    Exit status : ${workflow.exitStatus}
    results     : ${params.outdir}

    =======================================================================================
    """
    println summary.replaceAll(/(^|\n)\s+/, '\n')

    // If there were failed consensus assemblies, print a warning message
    def consensus_failure_strings = consensus_failures.value
    if (consensus_failure_strings.size() > 0) {
      def msg = """
      ===== CONSENSUS ASSEMBLY FAILURES =====
      WARNING: Consensus assembly failed for
      the following samples:
      ${consensus_failure_strings.join('\n')}
      =======================================
      """
      println msg.replaceAll(/(^|\n)\s+/, '\n')
    }

  }
}

