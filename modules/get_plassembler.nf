process get_plassembler {
  tag "DOWNLOADING PLASSEMBLER DATABASE"
  container 'quay.io/gbouras13/plassembler:1.6.2'
  
  output:
  path '*' , emit: plassembler_db

  script: 
  """
  plassembler download -d plasmid_db_plassembler
  """
}
