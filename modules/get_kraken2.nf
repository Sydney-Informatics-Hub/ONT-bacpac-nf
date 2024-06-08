process get_kraken2 {
  tag "DOWNLOADING KRAKEN2 DB: TODO ADD TAG"
    
  output:
  path '*' , emit: kraken2_db

  script: 
  """
  # this is so slow - consider using https://hpc.nih.gov/apps/aria2.html 
  wget https://genome-idx.s3.amazonaws.com/kraken/k2_standard_20240112.tar.gz

  tar -zxvf k2_standard_20240112.tar.gz
  """
}