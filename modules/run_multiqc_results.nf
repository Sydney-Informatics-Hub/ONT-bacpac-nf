process multiqc_results_report {
  tag "GENERATING RESULTS SUMMARY REPORT"
  container 'quay.io/biocontainers/multiqc:1.21--pyhdfd78af_0'
  publishDir "${params.outdir}/report/analysis_report", mode: 'copy'

  input:
  path(multiqc_results_config)
  path(kraken2)
  path(bakta)
  path(bakta_plasmids)
  path(phylogeny_heatmap_plot)
  path(consensus_warning_yaml)

  output:
  path ("*"), emit: multiqc

  script:
  """
  multiqc -c ${params.multiqc_results_config} .	
  """

}


