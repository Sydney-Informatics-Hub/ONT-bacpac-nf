process run_orthofinder{
  tag "GENERATE PHYLOGENY"
  container 'quay.io/biocontainers/orthofinder:2.5.5--hdfd78af_2'

  input:
  path(phylogeny_folder)

  output:
  path("phylogeny_tree"), emit: results
  path("phylogeny_tree/Results_tree/Species_Tree/SpeciesTree_rooted.txt"), emit: rooted_tree

  script:
  """
  # Description: Generate a phylogeny tree with orthofinder tool 
 
  # Using mafft and fastree
   orthofinder \\
        -f ${phylogeny_folder} \\
        -o phylogeny_tree \\
        -n tree \\
        -t ${task.cpus} \\
        -a ${task.cpus}
  """

}

