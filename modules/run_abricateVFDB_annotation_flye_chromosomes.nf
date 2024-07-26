process abricateVFDB_annotation_flye_chromosomes {
   tag "ANNOTATING FLYE ASSEMBLY WITH ABRICATE VFDB: ${barcode}"
   container 'quay.io/biocontainers/abricate:1.0.1--ha8f3691_2'
  publishDir "${params.outdir}/annotations/${barcode}", mode: 'symlink'
  
input:
  tuple val(barcode), path(medaka_flye)

output:
  tuple val(barcode), path("abricate/*"), emit: abricate_annotations, optional: true

script:
  """
  db_name='vfdb'
  mkdir -p abricate

  abricate ${medaka_flye}/consensus.fasta \\
     -db \${db_name} > abricate/${barcode}.txt  
  """

}
