process autocycler_cluster {
  tag "AUTOCYCLER CLUSTER: ${barcode}"
  container 'quay.io/biocontainers/autocycler:0.3.0--h3ab6199_0'
  errorStrategy { task.exitStatus == 1 ? 'ignore' : 'finish' }

  input:
  tuple val(barcode), path(autocycler_dir)

  output:
  tuple val(barcode), path("autocycler_cluster_out"), emit: cluster_out
  tuple val(barcode), path("autocycler_cluster_out/clustering/qc_pass/cluster_*"), emit: pass_clusters

  script:
  max_contigs_param = params.max_contigs && params.max_contigs.toString().isInteger() ? "--max_contigs ${params.max_contigs}" : ""
  """
  cp -rL ${autocycler_dir} autocycler_cluster_out 

  autocycler cluster \\
    --autocycler_dir autocycler_cluster_out \\
    ${max_contigs_param}
  """
}
