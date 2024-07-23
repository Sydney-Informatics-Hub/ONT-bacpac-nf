process generate_abricate_gene_matrix {
  tag "GENERATE ABRICATE gene_matrix for Phylogeny-heatmap image"  
  container 'depot.galaxyproject.org/singularity/python:3.8.3'

  input:
        path(abricate_output_all_samples)
        path(all_references_folder_abricate_output)
  	path(sampleid_species_table)

  output:
  	path("abricate_vfdb_output.txt"), emit: abricate_gene_matrix

  script: 
  """
  generate_abricate_gene_matrix.py \\
    ${abricate_output_all_samples} \\
    ${all_references_folder_abricate_output} \\
    ${sampleid_species_table}
  """
}
