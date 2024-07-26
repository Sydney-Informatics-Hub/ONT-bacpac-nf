process get_ncbi {
  tag "DOWNLOADING NCBI LOOKUP TABLE"
    
  output:
  path("ncbi_genome_lookup.txt") , emit: ncbi_lookup
  path("refseq_summary.txt") , emit: assembly_summary_refseq

  script: 
  """
  # Rename resource to provide context
  wget -O ncbi_genome_lookup.txt \\
    https://ftp.ncbi.nlm.nih.gov/genomes/GENOME_REPORTS/overview.txt

  # Summary file to pick the genome download link
  wget -O refseq_summary.txt \\
    https://ftp.ncbi.nlm.nih.gov/genomes/refseq/assembly_summary_refseq.txt
  """
}
