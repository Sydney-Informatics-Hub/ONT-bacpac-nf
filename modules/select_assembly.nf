process select_assembly {
  tag "${barcode}"  
  container 'python:3.8'

  input:
  tuple val(barcode), val(assemblies), path(busco_jsons)

  output:
  tuple val(barcode), path("best_assembly.txt")

  script:
  all_assemblers = assemblies.join(',')
  // Save to file (instead of print to stdout) for nextflow caching
  """
  compare_busco.py --all_assemblers ${all_assemblers} $busco_jsons > best_assembly.txt
  """
  
}
