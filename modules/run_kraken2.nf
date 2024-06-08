process kraken2 {
  tag "DETECTING POSSIBLE CONTAMINATION: ${barcode}"

  input:
  tuple val(barcode), path(trimmed_fq)
  path(kraken2_db)

  output:
  tuple val(barcode), path("*"), emit: kraken2_screen

  script: 
  """
  kraken2 \\
    --db ${kraken2_db} \\
    --report ${barcode}/${barcode}.k2report \\
    --report-minimizer-data \\
    --minimum-hit-groups ${trimmed_fq} \\
    --threads ${task.cpus} \\
    --output ${barcode}/${barcode}_k2_out.txt 
  
  # Is this necessary? It is not automated in the bash scripts 
  #extract_kraken_reads.py \
  #  -k ${barcode}/${barcode}_kraken.txt \\
  #  -r ${barcode}/${barcode}.k2report \
  #  -s ${input_fastq}\\
  #  -t ${tax_id} \\
  #  -o ${base_path}/pipeline/${sampleID}/${sampleID}_allfiles-cat-porechopped_filteredSpecies.fastq \
  #  --fastq-output

  # Has this been tested? Is it necessary? 
  # .k2report
  # https://github.com/DerrickWood/kraken2/blob/master/docs/MANUAL.markdown#sample-report-output-format

  # https://telatin.github.io/microbiome-bioinformatics/Kraken-to-Krona/
  # https://ftp.ncbi.nih.gov/pub/taxonomy/
  # wget https://ftp.ncbi.nih.gov/pub/taxonomy/taxdump.tar.gz
  """
}
