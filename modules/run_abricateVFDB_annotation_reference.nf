process abricateVFDB_annotation_reference {
  tag "DETECTING VIRULENCE GENES IN REFERENCE GENOME"
  container 'quay.io/biocontainers/abricate:1.0.1--ha8f3691_2'

input:
  path phylogeny_folder

output:
  path "abricate/*", emit: abricate_annotations, optional: true
  path "abricate_reference_report.annotated.tsv", emit: annotated_report, optional: true

script:
  """
  db_name='vfdb'
  mkdir -p abricate

  # List the files containing "REF" in the filename from the specified directory
  files=\$(find ${phylogeny_folder}/ -type f -name '*REF*.fna')

  rm -f abricate_reference_report.annotated.tsv
  
  # Iterate over the list of files
  for file_path in \${files}; do
    # Extract the base file name without the path and extension
    base_name=\$(basename "\${file_path}" .fna)
    echo "\$base_name"

    output_file=abricate/\${base_name}.tsv


    abricate \${file_path} \\
        -db \${db_name} > \${output_file}

    # Annotate the report with the reference name
    awk -v OFS="\t" -v ref="\${base_name}" 'NR == 1 { print \$0, "SAMPLE", "ASSEMBLER" } NR > 1 { print \$0, ref, "REFERENCE" }' \${output_file} >> abricate_reference_report.annotated.tsv
   
   done
  
  """

}
