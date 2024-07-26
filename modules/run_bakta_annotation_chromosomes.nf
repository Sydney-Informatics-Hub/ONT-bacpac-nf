process bakta_annotation_chromosomes {
  tag "ANNOTATING CONSENSUS ASSEMBLY WITH BATKA: ${barcode}"
  container 'quay.io/biocontainers/bakta:1.9.2--pyhdfd78af_0'
  publishDir "${params.outdir}/annotations/${barcode}", mode: 'symlink'

input:
  tuple val(barcode), path(medaka_consensus)
  path(bakta_db)

output:
  tuple val(barcode), path("${barcode}_bakta"), emit: bakta_annotations
  tuple val(barcode), path("${barcode}_bakta/${barcode}_chr.txt"), emit: bakta_annotations_multiqc

script:
  """
  for dir in ${medaka_consensus}; do  
  	cat \${dir}/consensus.fasta >> concatenated_consensus.fasta
  done

  bakta \\
    concatenated_consensus.fasta \\
    --db ${bakta_db} \\
    --output ${barcode}_bakta \\
    --prefix ${barcode}_chr \\
    --force \\
    --threads ${task.cpus}
   
  """
}
