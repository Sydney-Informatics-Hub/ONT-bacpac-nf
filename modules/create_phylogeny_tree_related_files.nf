process create_phylogeny_tree_related_files {
  container 'python:3.8'
  publishDir "${params.outdir}/taxonomy", mode: 'copy'
  
  input:
  path assembly_summary_refseq
  path kraken2_reports
  path bakta_results
  val bakta_assemblers

  output:
  path "phylogeny", emit: phylogeny_folder
  path "barcode_species_table_mqc.txt", emit: barcode_species_table

  script:
  all_assemblers = bakta_assemblers.join(',')
  """
  create_phylogenytree_related_files.py \\
    --assembly_summary_refseq ${assembly_summary_refseq} \\
    --all_assemblers ${all_assemblers} \\
    --kraken2_reports ${kraken2_reports} \\
    --bakta_results ${bakta_results}
  """
}
