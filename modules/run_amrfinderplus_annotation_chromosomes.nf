process amrfinderplus_annotation_chromosomes {
  tag "DETECTING AMR GENES: ${barcode}"
  container 'quay.io/biocontainers/ncbi-amrfinderplus:3.12.8--h283d18e_0'

input:
  tuple val(barcode), path(bakta_annotations)
  path(amrfinderplus_db)

output:
  tuple val(barcode), path("amrfinderplus/*"), emit: amrfinderplus_annotations

script:
  """
  mkdir -p amrfinderplus

  amrfinder -p ${bakta_annotations}/${barcode}.faa \\
    -d ${amrfinderplus_db}/latest > amrfinderplus/${barcode}.txt

  """

}
