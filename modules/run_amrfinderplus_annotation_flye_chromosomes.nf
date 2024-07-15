process amrfinderplus_annotation_flye_chromosomes {
  tag "ANNOTATING flye-chromosomes WITH AMRFINDERPLUS: ${barcode}"
  container 'quay.io/biocontainers/ncbi-amrfinderplus:3.12.8--h283d18e_0'

input:
  tuple val(barcode), path(bakta_annotations)
  path(amrfinderplus_db)

output:
  tuple val(barcode), path("amrfinderplus"), emit: amrfinderplus_annotations

  publishDir { "results/${barcode}" }, mode: 'copy'

script:
  """
  mkdir -p amrfinderplus

  amrfinder -p ${bakta_annotations}/${barcode}.faa \\
    -d ${amrfinderplus_db}/latest > amrfinderplus/${barcode}.txt

  """

}
