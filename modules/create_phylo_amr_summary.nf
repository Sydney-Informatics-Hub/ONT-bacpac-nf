process summarise_phylogeny_and_amr_reports {
  tag "SUMMARISING PHYLOGENETIC TREE AND AMR AND VIRULENCE GENES"
  container 'oras://community.wave.seqera.io/library/bioconductor-ggtree_r-ape_r-phytools_r-tidyverse:bd310f2405bed388'  
  publishDir "${params.outdir}/taxonomy", mode: 'copy'
  
  input:
  path rooted_tree
  path sample_species_table
  path amrfinderplus_reports, stageAs: "amrfinder_reports/*"
  path abricate_reports, stageAs: "abricate_reports/*"

  output:
  path "combined_plot_mqc.png", emit: combined_plot_mqc

  script:
  """
  summarise_phylogeny_and_amr_reports.R \\
    ${rooted_tree} \\
    ${sample_species_table} \\
    amrfinder_reports/ \\
    abricate_reports/
  """

}
