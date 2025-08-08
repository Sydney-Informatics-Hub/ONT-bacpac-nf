process get_bakta {
  tag "DOWNLOADING BAKTA DATABASE"
    
  output:
  path 'db-light' , emit: bakta_db

  script: 
  """
  bakta_db download --type light
  """
}
