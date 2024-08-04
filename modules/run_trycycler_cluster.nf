process trycycler_cluster {
  tag "CLUSTERING CONTIGS: ${barcode}"

  input:
  tuple val(barcode), path(unicycler_assembly), path(flye_assembly), path(trimmed_fq)

  output:
  tuple val(barcode), path("*_cluster"), emit: trycycler_cluster

  script: 
  """

  # This is a local insatllation of trycycler in which we have hashed the function "#build_tree(...)" in the source-code and installed the tool. We need to create a singularity image of this version of trycycler. Details in the PR    
  base_path_for_tools=/scratch/er01/ndes8648/pipeline_work/nextflow/PIPE-4747/github_repos/self_testing/trycycler_installation/local_copy_and_directly_from_github
  export PATH=$PATH:\${base_path_for_tools}/mash-Linux64-v2.3:\${base_path_for_tools}/minimap2:\${base_path_for_tools}/miniasm:\${base_path_for_tools}
  export R_LIBS="/scratch/er01/npd561"

  trycycler cluster \\
    --assemblies ${barcode}_unicycler_assembly/assembly.fasta ${barcode}_flye_assembly/assembly.fasta \\
    --reads ${barcode}_trimmed.fastq.gz \\
    --out_dir ${barcode}_cluster \\
    --min_contig_len ${params.trycycler_min_contig_length} \\
    --threads ${task.cpus}

 
  """
  

}
