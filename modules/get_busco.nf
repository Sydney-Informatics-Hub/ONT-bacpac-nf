process get_busco {
  tag "DOWNLOADING BUSCO DATABASE"
  container 'quay.io/biocontainers/busco:5.6.1--pyhdfd78af_0'

  output:
  path 'busco_downloads/', emit: busco_db

  script: 
  """
  mkdir -p busco_downloads/lineages/
  # TODO investgate issue with busco "download connection problem" and replace wget
  wget https://busco-data.ezlab.org/v5/data/lineages/bacteria_odb10.2024-01-08.tar.gz
  tar -xzf bacteria_odb10.2024-01-08.tar.gz -C busco_downloads/lineages/
  """
}
