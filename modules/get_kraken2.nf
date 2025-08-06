process get_kraken2 {
  tag "DOWNLOADING KRAKEN2 DATABASE"
    
  output:
  path 'kraken2_db' , emit: kraken2_db

  script: 
  """
  mkdir -p kraken2_db
  cd kraken2_db
  
  wget ${params.kraken2_db_url}

  tar -zxvf \$(basename ${params.kraken2_db_url})
  """
}