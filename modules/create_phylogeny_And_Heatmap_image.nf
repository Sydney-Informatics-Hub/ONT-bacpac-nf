process create_phylogeny_And_Heatmap_image {
	tag "PLOTTING PHYLOGENETIC TREE WITH AMR AND VIRULENCE GENES"
  container 'oras://community.wave.seqera.io/library/bioconductor-ggtree_r-ape_r-phytools_r-tidyverse:bd310f2405bed388'  
  publishDir "${params.outdir}/taxonomy", mode: 'copy'
  
  input:
  path(phylogeny_tree_base_path)
  path(amrfinderplus_gene_matrix)
	path(abricate_gene_matrix)

  output:
  path ("combined_plot_mqc.png"), emit: combined_plot_mqc

  script:
  """
  create_phylogeny_And_heatmap.r \\
    ${phylogeny_tree_base_path} \\
    ${amrfinderplus_gene_matrix} \\
    ${abricate_gene_matrix}
  """

}
