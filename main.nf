#!/usr/bin/env nextflow

// To use DSL-2 will need to include this
nextflow.enable.dsl=2

// Import processes or subworkflows to be run in the workflow
include { denovo } from './subworkflows/denovo'
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
include { autocycler } from './subworkflows/autocycler'
include { bandage } from './modules/run_bandage'
include { generate_bandage_report } from './modules/generate_bandage_report'
include { select_assembly } from './modules/select_assembly'
include { medaka_polish_denovo } from './modules/run_medaka_polish_denovo'
include { plassembler } from './modules/run_plassembler'
include { bakta_annotation_plasmids } from './modules/run_bakta_annotation_plasmids'
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
include { summarise_phylogeny_and_amr_reports } from './modules/create_phylo_amr_summary'
include { generate_consensus_warnings } from './modules/generate_consensus_warnings'
include { multiqc_report } from './modules/run_multiqc'
include { multiqc_results_report } from './modules/run_multiqc_results'

// Print a header for your pipeline 
def printInfo() {
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
}

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

  printInfo()

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
      kraken2_db = channel.fromPath(params.kraken2_db).first()
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
      zipped_fqs = channel.fromPath(params.input_directory + '/*.zip')
        .map { f -> [ f.baseName, f ] }
      pre_unzipped_fq_dirs = channel.fromPath(params.input_directory + '/*/*.{fq,fastq}.gz')  // For now we need to require .gz FASTQs due to requirements of pigz
        .map { f -> [ f.parent.baseName, f.parent ] }
        .unique()
    } else {
      // VALIDATE SAMPLESHEET
      log.info "READING ZIPPED FASTQS FROM SAMPLESHEET `${params.samplesheet}`"
      samplesheet_ch = channel.fromPath(params.samplesheet).first()
        .splitCsv( header: true )
        .map { row -> [ row.barcode, file(row.file_path) ] }
      zipped_fqs = samplesheet_ch
        .filter { _bc, f -> f.isFile() && f.name.endsWith('.zip') }
      pre_unzipped_fq_dirs = samplesheet_ch
        .filter { _bc, f -> f.isDirectory() }
    }

    unzipped_fq_dirs = unzip_fastqs(zipped_fqs)
      .mix(pre_unzipped_fq_dirs)
  }

  // CONCATENATE FQS PER SAMPLE
  concat_fastqs(unzipped_fq_dirs)

  // QC SUMMARY OF RAW INPUTS 
  // INPUT FILE GENERATED BY THE ONT MACHINE 
  sequencing_summary = channel.fromPath(params.sequencing_summary).first()

  nanoplot_summary(sequencing_summary)
  pycoqc_summary(sequencing_summary)
  
  // PORECHOP NANOPORE ADAPTERS 
  porechop(concat_fastqs.out.concat_fq)

  // SCREEN FOR CONTAMINANTS 
  kraken2(porechop.out.trimmed_fq, kraken2_db)

  // DE NOVO GENOME ASSEMBLIES
  denovo_fqs = porechop.out.trimmed_fq
    .map { barcode, fq -> [ barcode, null, fq ] }
  denovo(denovo_fqs, plassembler_db)

  // RUN AUTOCYCLER
  autocycler(porechop.out.trimmed_fq, denovo.out.assemblies, plassembler_db)

  polished_consensus_per_barcode = autocycler.out.polished_consensus_per_barcode
  consensus_gfa_per_barcode = autocycler.out.consensus_gfa_per_barcode
  autocycler_metrics = autocycler.out.metrics

  // Identify failed barcodes and create a list of their names
  consensus_successes = polished_consensus_per_barcode
    .ifEmpty([null, null, null])  // Gives us something to join against, will be filtered out below
  consensus_failures = concat_fastqs.out.concat_fq
    .map { barcode, _fq -> barcode }
    .unique()
    .join(consensus_successes, remainder: true)
    .filter { x ->
      x.size() == 2 && !x[1]
    }
    .map { barcode, _nullval -> barcode }
    .collect()

  // Generate MultiQC-ready YAML file of failed barcodes
  consensus_method = channel.value('autocycler')
  generate_consensus_warnings(consensus_failures, consensus_method)
  consensus_warnings = generate_consensus_warnings.out.mqc_yaml
    .ifEmpty([])

  // RUN BANDAGE ON AUTOCYCLER GRAPHS
  // DE NOVO ASSEMBLY GRAPHS
  // AND PLASEMBLER GRAPHS
  denovo_graphs = denovo.out.graphs
    .map { barcode, _subset, assembler, graph -> [ barcode, assembler, graph ] }
  graphs_for_bandage =
    denovo_graphs
    .mix(consensus_gfa_per_barcode)
    .filter { _barcode, _assembly, graph ->
      graph.size() > 0
    }

  bandage(graphs_for_bandage)

  // Generate MultiQC-ready Bandage report
  all_bandage_plots = bandage.out.bandage_plot
    .map { _barcode, _assembly, plot -> plot }
    .collect()
  generate_bandage_report(all_bandage_plots)

  // MEDAKA: POLISH DE NOVO ASSEMBLIES
  unpolished_denovo_assemblies = denovo.out.assemblies
    .map { barcode, _subset, assembler, assembly_dir -> [ barcode, assembler, assembly_dir ] }
    .combine(porechop.out.trimmed_fq, by: 0)
  medaka_polish_denovo(unpolished_denovo_assemblies)

  // ASSEMBLY QC
  all_polished = polished_consensus_per_barcode
    .mix(medaka_polish_denovo.out.assembly)

  // TODO: probably better to collect all per-barcode assemblies in one quast
  // run to void a parsing/merging step
  quast_qc_chromosomes(all_polished)
  busco_qc_chromosomes(all_polished, busco_db)
  
  // SELECT "BEST" ASSEMBLY
  // TODO: Discuss better approaches. Currently selects the best assembly per
  // barcode by most Complete BUSCO % 
  barcode_busco_jsons =
    // Gather all jsons for each barcode
    busco_qc_chromosomes.out.json_summary
    .filter { _barcode, assembler, _json -> assembler != 'plassembler' }  // Use chromosome assemblies for comparison
    .groupTuple()

  select_assembly(barcode_busco_jsons)
  
  best_chr_assembly = 
    select_assembly.out
    .map { barcode, txt ->
      // best assembly stored in txt file for pipeline caching
      String best = txt.splitText()[0].strip()  // TODO: Is there a better way to do this?
      return [barcode, best]
    }
    .join(all_polished, by: [0, 1])

  // Get plasmids assemblies for barcodes where we are using the de novo assemblies
  // (consensus assemblies already include plasmids so we don't need to process these separately)
  denovo_plasmid_assemblies =
    // Get barcodes for which we are using the de novo assemblies
    best_chr_assembly
    .filter { _barcode, assembler, _fasta -> assembler != 'consensus' }
    .map { barcode, _assembler, _fasta -> [ barcode, 'plassembler' ] }
    .unique()
    // Join with all_polished to get just the plasmid assemblies
    // to be processed in parallel with de novo chromosomes
    .join ( all_polished, by: [0, 1] )

  best_chr_assembly = best_chr_assembly
    .mix(denovo_plasmid_assemblies)

  // NOTE: best_chr_assembly will either be:
  // an autocycler assembly (including plassembler output); or
  // a de novo chr assembly + a plassembler assembly (as separate elements)

  // ANNOTATE THE BEST CHROMOSOMAL ASSEMBLY PER-BARCODE
  // BAKTA: Annotate gene features
  bakta_annotation_chromosomes(best_chr_assembly, get_bakta.out.bakta_db)

  // ABRICATE: Annotate VFDB genes
  abricateVFDB_annotation_chromosomes(best_chr_assembly)

  // AMRFINDERPLUS: Annotate AMR genes
  amrfinderplus_annotation_chromosomes(
    bakta_annotation_chromosomes.out.faa,
    amrfinderplus_db
  )

  // CREATE FILES FOR PHYLOGENETIC TREE BUILDING
  // Collect all the output (annotation) reports required for tree building
  // NOTE: For de novo assemblies (i.e. autocycler consensus has failed),
  // phylogenetic trees will only be built from the de novo chromosome asemblies
  // and won't use the plasmid assemblies from plassembler
  kraken2_reports =
    // Collect all k2 reports and drop barcodes
    kraken2.out
    .map { _barcode, k2_report -> k2_report }
    .collect()

  bakta_results_faas =
    bakta_annotation_chromosomes.out.faa
    // Remove de novo plasmid assemblies
    .filter { _barcode, assembler, _faa -> assembler != 'plassembler' }
    .map { _barcode, _assembler, faa -> faa }
    .collect()

  bakta_assemblers =
    bakta_annotation_chromosomes.out.faa
    // Remove de novo plasmid assemblies
    .filter { _barcode, assembler, _info -> assembler != 'plassembler' }
    .map { _barcode, assembler, _faa -> assembler }
    .unique()
    .collect()

  create_phylogeny_tree_related_files(
    get_ncbi.out.assembly_summary_refseq,
    kraken2_reports,
    bakta_results_faas,
    bakta_assemblers
  )

  barcode_species_table = create_phylogeny_tree_related_files.out.barcode_species_table

  // ORTHOFINDER: Infer phylogeny using orthologous genes
  phylogeny_in = create_phylogeny_tree_related_files.out.phylogeny_folder
  run_orthofinder(phylogeny_in)

  // ANNOTATE REFERENCE STRAINS
  // AMRFINDERPLUS: Annotate AMR genes
  amrfinderplus_annotation_reference(
    phylogeny_in,
    amrfinderplus_db
  )

  // ABRICATE: Annotate VFDB genes
  abricateVFDB_annotation_reference(phylogeny_in)

  // Gather all abricate and amrfinderplus reports
  amrfinder_reports = amrfinderplus_annotation_chromosomes.out.annotated_report
    .map { _barcode, _assembler, report -> report }
    .mix(amrfinderplus_annotation_reference.out.annotated_report)
    .collect()

  abricate_reports = abricateVFDB_annotation_chromosomes.out.annotated_report
    .map { _barcode, _assembler, report -> report }
    .mix(abricateVFDB_annotation_reference.out.annotated_report)
    .collect()

  // R: Plot phylogeny and heatmap
  summarise_phylogeny_and_amr_reports(
    run_orthofinder.out.rooted_tree,
    barcode_species_table,
    amrfinder_reports,
    abricate_reports
  )

  // BAKTA: Annotate plasmid gene features
  plassembler_fasta = denovo.out.plassembler_fasta
    .map { barcode, _subset, fasta -> [ barcode, fasta ] }
  bakta_annotation_plasmids(plassembler_fasta, get_bakta.out.bakta_db)

  // SUMMARISE RUN WITH MULTIQC REPORT
  // Ensure all necessary inputs are available for MultiQC, even if some are empty
  nanoplot_required_for_multiqc = nanoplot_summary.out.nanoplot_summary.ifEmpty([])
  pycoqc_required_for_multiqc = pycoqc_summary.out.pycoqc_json.ifEmpty([])

  kraken2_required_for_multiqc = 
    kraken2.out.kraken2_screen
    .map { _barcode, report -> report }
    .collect()
    .ifEmpty([])

  quast_required_for_multiqc = 
    quast_qc_chromosomes.out.tsv
    .map { _barcode, _assembler, tsv -> tsv }
    .collect()

  bakta_required_for_multiqc =
    bakta_annotation_chromosomes.out.txt
    .map { _barcode, _assembler, txt -> txt }
    .collect()

  busco_required_for_multiqc =
    busco_qc_chromosomes.out.txt_summary
    .map { _barcode, _assembler, txt -> txt }
    .collect()

  bakta_plasmids_required_for_multiqc = 
    bakta_annotation_plasmids.out.bakta_annotations
    .map { _barcode, annotations -> annotations }
    .collect()
    .ifEmpty([])

  phylogeny_heatmap_plot_required_for_multiqc = 
    summarise_phylogeny_and_amr_reports.out.combined_plot_mqc
    .ifEmpty([])

  bandage_report = generate_bandage_report.out.bandage_report

  autocycler_metrics_for_mqc = autocycler_metrics
    .ifEmpty([])

  multiqc_config = channel.value("${projectDir}/assets/multiqc_config.yml")
  multiqc_results_config = channel.value("${projectDir}/assets/multiqc_results_config.yml")

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
    def consensus_failure_strings = consensus_failures.ifEmpty([]).value
    if (consensus_failure_strings.size() > 0) {
      def msg = """
      ===== CONSENSUS ASSEMBLY FAILURES =====
      WARNING: Consensus assembly failed for
      the following samples:

      ${consensus_failure_strings.join('\n')}

      For each of these samples, one of the
      de novo assemblies was chosen for
      downstream analyses
      =======================================
      """
      println msg.replaceAll(/(^|\n)\s+/, '\n')
    }

  }
}

