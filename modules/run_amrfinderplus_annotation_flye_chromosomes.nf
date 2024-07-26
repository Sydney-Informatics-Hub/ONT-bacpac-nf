process amrfinderplus_annotation_flye_chromosomes {
  tag "DETECTING AMR GENES: ${barcode}"
  container 'quay.io/biocontainers/ncbi-amrfinderplus:3.12.8--h283d18e_0'
  publishDir "${params.outdir}/annotations/${barcode}", mode: 'symlink'
  
input:
  tuple val(barcode), path(bakta_annotations)
  path(amrfinderplus_db)

output:
  tuple val(barcode), path("amrfinderplus/*"), emit: amrfinderplus_annotations, optional: true

script:
  """
  mkdir -p amrfinderplus

  amrfinder -p ${barcode}_bakta/${barcode}_chr.faa \\
    -d ${amrfinderplus_db}/latest > amrfinderplus/${barcode}.txt

  """

}
