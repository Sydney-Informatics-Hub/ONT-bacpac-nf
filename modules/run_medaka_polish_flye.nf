process medaka_polish_flye {
  tag "POLISHING FLYE ASSEMBLY: ${barcode}"
  container 'quay.io/biocontainers/medaka:1.11.3--py39h05d5c5e_0'

  input:
  tuple val(barcode), path(flye_only), path(flye_chr_assembly), path(flye_assembly), path(trimmed_fq)

  //output:
  //tuple val(barcode), path("*"), emit: consensus_polished, optional: true

  script:
  """
  #medaka_consensus \\
  #	  -i ${barcode}_trimmed.fastq.gz \\
  #  -d ${barcode}_flye_assembly/Chr_contigs/flyeChromosomes.fasta \\
  #	  -o medaka_flye \\
  #	  -t ${task.cpus}

  medaka_consensus \\
	 -i ${trimmed_fq} \\
	 -d ${flye_chr_assembly}/flyeChromosomes.fasta \\
	 -o ${barcode}_medaka_flye \\
	 -t ${task.cpus}

  """
}
