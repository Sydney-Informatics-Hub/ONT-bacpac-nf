process get_plassembler {
  tag "DOWNLOADING PLASSEMBLER DATABASE: TODO ADD TAG"
  container 'quay.io/biocontainers/plassembler:1.6.2--pyhdfd78af_0'
    
  output:
  path '*' , emit: plassembler_db

  script: 
  """
  plassembler download -d plasmid_db_plassembler
  """
}