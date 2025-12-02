process autocycler_trim {
  tag "AUTOCYCLER TRIM: ${sample}"
  container 'quay.io/biocontainers/autocycler:0.3.0--h3ab6199_0'

  input:
  tuple val(sample), val(cluster_id), path(cluster_dir, stageAs: "cluster_dir")

  output:
  tuple val(sample), val(cluster_id), path("${cluster_id}"), emit: trimmed_cluster

  script:
  """
  cp -rL cluster_dir ${cluster_id}

  autocycler trim \\
    --cluster_dir ${cluster_id} \\
    --threads ${task.cpus}
  """
}
