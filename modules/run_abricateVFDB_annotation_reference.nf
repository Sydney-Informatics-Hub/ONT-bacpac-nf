process abricateVFDB_annotation_reference {
  tag "ANNOTATING reference WITH ABRICATE-VFDB"
  container 'quay.io/biocontainers/abricate:1.0.1--ha8f3691_2'

input:
  path(phylogeny_folder)

output:
  path("abricate/*"), emit: abricate_annotations, optional: true

  //publishDir { "results/reference" }, mode: 'copy'

script:
  """
  db_name='vfdb'
  mkdir -p abricate

  # List the files containing "REF" in the filename from the specified directory
  files=\$(find ${phylogeny_folder}/ -type f -name '*REF*.fna')
  
  # Iterate over the list of files
  for file_path in \${files}; do
    # Extract the base file name without the path and extension
    base_name=\$(basename "\${file_path}" .fna)
    echo "\$base_name"

    output_file=abricate/\${base_name}.txt


    abricate \${file_path} \\
        -db \${db_name} > \${output_file}
   
   done
  
  """

}
