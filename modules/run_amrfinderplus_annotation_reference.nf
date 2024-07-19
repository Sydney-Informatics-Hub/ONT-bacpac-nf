process amrfinderplus_annotation_reference
  {
  tag "ANNOTATING reference WITH AMRFINDERPLUS"
  container 'quay.io/biocontainers/ncbi-amrfinderplus:3.12.8--h283d18e_0'

input:
  path(phylogeny_folder)
  path(amrfinderplus_db)

output:
  path("amrfinderplus_reference/*"), emit: amrfinderplus_annotations, optional: true

  //publishDir { "results/reference" }, mode: 'copy'

script:
  """
  mkdir -p amrfinderplus_reference

  # List the files containing "REF" in the filename from the specified directory
  files=\$(find ${phylogeny_folder}/ -type f -name '*REF*.faa')
  
  # Iterate over the list of files
  for file_path in \${files}; do
    # Extract the base file name without the path and extension
    base_name=\$(basename "\${file_path}" .faa)
    echo "\$base_name"

    output_file=amrfinderplus_reference/\${base_name}.txt

    amrfinder -p \${file_path} \\
       -d ${amrfinderplus_db}/latest > \${output_file} 
   
   done
  
  """

}
