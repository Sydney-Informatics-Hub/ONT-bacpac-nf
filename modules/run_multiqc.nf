process multiqc_report 
  {
  tag "MULTIQC FOR ALL SAMPLES"
  container 'quay.io/biocontainers/multiqc:1.21--pyhdfd78af_0'

  input:
  path(pycoqc)
  path(nanoplot)
  path(multiqc_config_file)
  path(kraken2)
  path(quast)
  path(bakta)
  path(bakta_plasmids)
  path(busco)
  path(busco_plasmids)

  //output:

  script:
  """

  # QUAST
  # (1) Needed to rename quast logs from report.tsv to sampleid.tsv in run_quast*.nf ; to be able to pass in .collect()
  # (2) However multiqc only reads a file named report.tsv
  # (3) So copied the sampleid.tsv into sampleid/report.tsv
  # Works
   
  for dir in $quast; do
	file_name=\$(basename "\${dir}")
	# Remove the .tsv extension
	file_name_no_ext="\${file_name%.tsv}"
	dir_path=\$(dirname "\${dir}")
      
	mkdir "\${dir_path}/\${file_name_no_ext}"          
        new_path="\${dir_path}/\${file_name_no_ext}/report.tsv"
        cp "\${dir}" "\${new_path}"    
  done

  multiqc -c ${multiqc_config_file} .	
  """

}


