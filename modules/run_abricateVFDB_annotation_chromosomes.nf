process abricateVFDB_annotation_chromosomes {
  tag "ANNOTATING CONSENSUS ASSEMBLY WITH ABRICATE VFDB: ${barcode}"
  container 'quay.io/biocontainers/abricate:1.0.1--ha8f3691_2'
  publishDir "${params.outdir}/annotations/${barcode}", mode: 'symlink'

input:
  tuple val(barcode), path(medaka_consensus)

output:
  tuple val(barcode), path("abricate/*"), emit: abricate_annotations, optional: true 

script:
  """
  for dir in ${medaka_consensus}; do  
  	cat \${dir}/consensus.fasta >> concatenated_consensus.fasta
  done

  db_name='vfdb'
  mkdir -p abricate

  abricate concatenated_consensus.fasta \\
	-db \${db_name} > abricate/${barcode}.txt
 
  """

}
