process get_ncbi {
  tag "DOWNLOADING NCBI LOOKUP TABLE"
    
  output:
  path("ncbi_genome_lookup.txt") , emit: ncbi_lookup
  path("refseq_summary.txt") , emit: assembly_summary_refseq


  script: 
  """
  # Download both files simultaneously using aria2
  aria2c -x 16 -s 16 \\
    https://ftp.ncbi.nlm.nih.gov/genomes/GENOME_REPORTS/overview.txt \\
    https://ftp.ncbi.nlm.nih.gov/genomes/refseq/assembly_summary_refseq.txt

  # Rename the downloaded files to provide context
  mv overview.txt ncbi_genome_lookup.txt
  mv assembly_summary_refseq.txt refseq_summary.txt
  """
}
