process select_assembly_new {
  tag "${barcode}"  
  container 'python:3.12'

  input:
  tuple val(barcode), path(busco_jsons)

  output:
  tuple val(barcode), stdout

  script: 
  """
  compare_busco.py $busco_jsons
  """
}
