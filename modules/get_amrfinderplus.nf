process get_amrfinderplus {
  tag "UPDATING AMRFINDERPLUS DATABASE: TODO ADD TAG"
  container 'quay.io/biocontainers/ncbi-amrfinderplus:3.12.8--h283d18e_0'
    
  output:
  path '*' , emit: amrfinderplus_db

  script: 
  """
  # See: https://github.com/ncbi/amr/wiki/Upgrading#database-updates
  amrfinder_update \\
    -d amrfinderplus_db
  """
}