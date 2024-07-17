process generate_amrfinderplus_gene_matrix {
  tag "GENERATE AMRFIDNERPLUS gene_matrix for Phylogeny-heatmap image"  
  //container 'depot.galaxyproject.org/singularity/python:3.8.3'

  input:
        path(amrfinderplus_output_all_samples)
        path(all_references_folder_amrfinderplus_output)
  	path(sampleid_species_table)

  output:
  	path("amrfinderplus_output.txt"), emit: amrfinderplus_gene_matrix
  //	path("sampleID_species_table_mqc.txt"), emit: sampleID_species_table

  script: 
  """
  generate_amrfinderplus_gene_matrix.py \\
    ${amrfinderplus_output_all_samples} \\
    ${all_references_folder_amrfinderplus_output} \\
    ${sampleid_species_table}
  """
}
