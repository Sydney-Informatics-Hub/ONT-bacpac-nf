process create_samplesheet_for_processed {
  tag "CREATING SAMPLESHEET: ${params.input}"

  input:
  val(all_processed_samples)

  output:
  path('samplesheet.txt') , emit: samplesheet_processed 

  script:
  """
  echo "sample_ids" > samplesheet.txt
    
  for sampleid in ${all_processed_samples};
    do
    sampleid_stripped=\${sampleid//[\\[\\],]/}
    echo \$sampleid_stripped >> samplesheet.txt
  done
  """
}


