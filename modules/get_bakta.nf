process get_bakta {
  tag "DOWNLOADING BAKTA DATABASE"
    
  output:
  path 'db-light' , emit: bakta_db

  script: 
  """
  # replace wget with aria2c 
  wget https://zenodo.org/records/10522951/files/db-light.tar.gz
  tar -zxvf db-light.tar.gz
  """
}
