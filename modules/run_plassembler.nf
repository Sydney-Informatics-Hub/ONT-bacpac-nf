process plassembler {
  tag "DETECTING PLASMIDS AND OTHER MOBILE ELEMENTS: ${barcode}"
  container 'quay.io/gbouras13/plassembler:1.6.2'
  publishDir "${params.outdir}/assemblies", mode: 'symlink'

  input:
  tuple val(barcode), path(trimmed_fq), path(flye_assembly)
  path plassembler_db 

  output:
  tuple val(barcode), path("${barcode}_plassembler/plassembler_plasmids.fasta"), emit: plassembler_fasta, optional: true
  tuple val(barcode), path("${barcode}_plassembler/plassembler_plasmids.gfa"), emit: plassembler_gfa
  tuple val(barcode), path("${barcode}_plassembler/plassembler_summary.tsv"), emit: plassembler_summary
  tuple val(barcode), path("${barcode}_plassembler/plassembler_*.log"), emit: plassembler_log  
  tuple val(barcode), path("${barcode}_plassembler/flye_output"), emit: flye_output
  tuple val(barcode), path("${barcode}_plassembler/unicycler_output"), emit: unicycler_output
  tuple val(barcode), path("${barcode}_plassembler/logs"), emit: logs

  script:
  """
  plassembler long \\
    -d plasmid_db_plassembler \\
	  -l ${barcode}_trimmed.fastq.gz \\
    --flye_assembly ${barcode}_flye_assembly/assembly.fasta \\
    --flye_info ${barcode}_flye_assembly/assembly_info.txt \\
    -o ${barcode}_plassembler \\
    -t ${task.cpus} -f
  
  # Check if the resulting .fasta file is empty
  if [ -s ${barcode}_plassembler/plassembler_plasmids.fasta ]; then
    echo "The .fasta file contains plasmid sequence. Proceeding with output."
  else
    echo "The .fasta file is empty, no plasmids detected. Removing from output."
    rm -f ${barcode}_plassembler/plassembler_plasmids.fasta
  fi
  """
}
