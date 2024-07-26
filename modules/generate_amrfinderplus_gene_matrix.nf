process generate_amrfinderplus_gene_matrix {
  tag "GENERATING AMRFINDERPLUS GENE MATRIX FOR ALL SAMPLES: ${params.input}"  
  container 'depot.galaxyproject.org/singularity/python:3.8.3'
  publishDir "${params.outdir}/taxonomy", mode: 'symlink'
  
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
