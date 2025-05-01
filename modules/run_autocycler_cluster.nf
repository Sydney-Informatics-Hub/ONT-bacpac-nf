process autocycler_cluster {
  tag "AUTOCYCLER CLUSTER: ${barcode}"
  container 'quay.io/biocontainers/autocycler:0.3.0--h3ab6199_0'

  // errorStrategy { task.exitStatus == 1 ? 'ignore' : 'terminate' } 

  input:
  tuple val(barcode), path(autocycler_dir)

  output:
  tuple val(barcode), path("autocycler_cluster_out"), emit: cluster_out
  tuple val(barcode), path("autocycler_cluster_out/clustering/qc_pass/cluster_*"), emit: pass_clusters

  script:
  """
  cp -rL ${autocycler_dir} autocycler_cluster_out 

  autocycler cluster \\
    --autocycler_dir autocycler_cluster_out
  """
}
