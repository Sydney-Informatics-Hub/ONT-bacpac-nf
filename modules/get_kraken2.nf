process get_kraken2 {
  tag "DOWNLOADING KRAKEN2 DB: TODO ADD TAG"
    
  output:
  path 'kraken2_db' , emit: kraken2_db

  script: 
  """
  mkdir -p kraken2_db
  cd kraken2_db
  
  # this is so slow - consider using https://hpc.nih.gov/apps/aria2.html 
  wget https://genome-idx.s3.amazonaws.com/kraken/k2_standard_20240112.tar.gz

  tar -zxvf k2_standard_20240112.tar.gz
  """
}