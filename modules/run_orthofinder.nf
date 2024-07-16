process run_orthofinder{
  tag "RUN ORTHOFINDER to generate Phylogeny tree"
  container 'quay.io/biocontainers/orthofinder:2.5.5--hdfd78af_2'

input:
  path(phylogeny_folder)

  output:
  //tuple val(barcode), val("${barcode}_${reconciled_dir}"), path("${barcode}_${reconciled_dir}_msa"), emit: three_msa
  path("phylogeny_tree")


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

