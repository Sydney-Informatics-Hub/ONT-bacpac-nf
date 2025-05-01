process autocycler_combine {
  tag "AUTOCYCLER COMBINE: ${barcode}"
  container 'quay.io/biocontainers/autocycler:0.3.0--h3ab6199_0'
  publishDir "${params.outdir}/assemblies/${barcode}_consensus", mode: 'copy'

  // errorStrategy { task.exitStatus == 1 ? 'ignore' : 'terminate' } 

  input:
  tuple val(barcode), path(autocycler_cluster_dir, stageAs: "autocycler_cluster_dir"), path(pass_cluster_dirs)

  output:
  tuple val(barcode), path("autocycler_out"), emit: autocycler_out

  script:
  """
  cp -rL autocycler_cluster_dir autocycler_out

  # Remove the passing cluster directories from the autocycler cluster directory
  # and replace with the pass_cluster_dirs from the trim + resolve stages
  rm -r autocycler_out/clustering/qc_pass/*
  cp -rL ${pass_cluster_dirs} autocycler_out/clustering/qc_pass/

  autocycler combine \\
    --autocycler_dir autocycler_out \\
    --in_gfas autocycler_out/clustering/qc_pass/cluster_*/5_final.gfa
  """
}
