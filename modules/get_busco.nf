process get_busco {
  tag "DOWNLOADING BUSCO DATABASE"
  container 'quay.io/biocontainers/busco:5.6.1--pyhdfd78af_0'

  output:
  path 'busco_downloads/', emit: busco_db

  script: 
  """
  # Get list of all BUSCO datasets
  busco --list-datasets > datasets

  # Get the latest bacteria dataset
  DB=$(grep -oE ' bacteria_odb\w+' datasets | sed -E -e 's/^ //g')

  # Download the database
  busco --download \$DB
  """
}
