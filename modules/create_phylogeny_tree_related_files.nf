process create_phylogeny_tree_related_files {
  tag "PREPARING INPUTS FOR PHYLOGENETIC TREE"  
  container 'depot.galaxyproject.org/singularity/python:3.8.3'

  input:
  path(assembly_summary_refseq)
  path(kraken2_reports)
	path(bakta_results)

  output:
	path("phylogeny"), emit: phylogeny_folder
	path("barcode_species_table_mqc.txt"), emit: barcode_species_table

  script: 
  """
  create_phylogenytree_related_files.py \\
    ${assembly_summary_refseq} \\
    ${kraken2_reports} \\
    ${bakta_results}
  """
}
