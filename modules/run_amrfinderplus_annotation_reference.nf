process amrfinderplus_annotation_reference {
    tag "DETECTING AMR GENES IN REFERENCE GENOME"
  container 'quay.io/biocontainers/ncbi-amrfinderplus:3.12.8--h283d18e_0'

input:
  path phylogeny_folder
  path amrfinderplus_db

output:
  path "amrfinderplus_reference/*", emit: amrfinderplus_annotations, optional: true
  path "amrfinderplus_reference_report.annotated.tsv", emit: annotated_report, optional: true

script:
  """
  mkdir -p amrfinderplus_reference

  # List the files containing "REF" in the filename from the specified directory
  files=\$(find ${phylogeny_folder}/ -type f -name '*REF*.faa')

  rm -f amrfinderplus_reference_report.annotated.tsv
  
  # Iterate over the list of files
  for file_path in \${files}; do
    # Extract the base file name without the path and extension
    base_name=\$(basename "\${file_path}" .faa)
    echo "\$base_name"

    output_file=amrfinderplus_reference/\${base_name}.tsv

    amrfinder -p \${file_path} \\
       -d ${amrfinderplus_db}/latest > \${output_file} 

    # Annotate the report with the reference name
    if [ ! -f "amrfinderplus_reference_report.annotated.tsv" ]
    then
      awk -v OFS="\t" -v ref="\${base_name}" 'NR == 1 { print "Sample", "Assembler", \$0 }' \${output_file}  > amrfinderplus_reference_report.annotated.tsv
    fi
    awk -v OFS="\t" -v ref="\${base_name}" 'NR > 1 { print ref, "REFERENCE", \$0 }' \${output_file}  >> amrfinderplus_reference_report.annotated.tsv
   
   done
  
  """

}
