process multiqc_report {
  tag "GENERATING SUMMARY REPORT"
  container 'quay.io/biocontainers/multiqc:1.21--pyhdfd78af_0'
  publishDir "${params.outdir}/report", mode: 'copy'

  input:
  path(pycoqc)
  path(nanoplot)
  path(multiqc_config)
  path(quast)
  path(busco)
  path(bandage_report)
  path(autocycler_metrics)
  path(consensus_warning_yaml)

  output:
  path ("*"), emit: multiqc

  script:
  """
  for dir in $quast; do
	file_name=\$(basename "\${dir}")
	# Remove the .tsv extension
	file_name_no_ext="\${file_name%.tsv}"
	dir_path=\$(dirname "\${dir}")
      
	mkdir "\${dir_path}/\${file_name_no_ext}"          
        new_path="\${dir_path}/\${file_name_no_ext}/report.tsv"
        cp "\${dir}" "\${new_path}"    
  done

  multiqc -c ${params.multiqc_config} .	
  """

}


