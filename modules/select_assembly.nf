process select_assembly {
  tag "${barcode}"  
  container 'python:3.8'

  input:
  tuple val(barcode), path(busco_jsons)

  output:
  tuple val(barcode), path("best_assembly.txt")

  script: 
  // Save to file (instead of print to stdout) for nextflow caching
  """
  compare_busco.py $busco_jsons > best_assembly.txt
  """
  
}
