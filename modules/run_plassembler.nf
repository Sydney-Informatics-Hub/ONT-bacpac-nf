process plassembler {
  tag "DETECTING PLASMIDS AND OTHER MOBILE ELEMENTS: ${barcode}"
  container 'quay.io/gbouras13/plassembler:1.6.2'

  input:
  tuple val(barcode), path(trimmed_fq), path(flye_assembly)
  path plassembler_db 

  output:
  tuple val(barcode), path("*"), emit: plasmids

  script:
  """
  plassembler long \\
    -d plasmid_db_plassembler \\
	  -l ${barcode}_trimmed.fastq.gz \\
    --flye_assembly ${barcode}_flye_assembly/assembly.fasta \\
    --flye_info ${barcode}_flye_assembly/assembly_info.txt \\
    -o ${barcode}_plassembler \\
    -t ${task.cpus} -f
  """
}
