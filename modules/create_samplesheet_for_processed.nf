// Process to create the samplesheet.txt from the collected barcodes
process create_samplesheet_for_processed {
  
    tag "CREATE samplesheet.txt of all processed samples"

    input:
    val(all_processed_samples)

    output:
    path('samplesheet.txt') , emit: samplesheet_processed 

    script:
    """
    echo "sample_ids" > samplesheet.txt
    
    for sampleid in ${all_processed_samples} ;
      do
        sampleid_stripped=\${sampleid//[\\[\\],]/}
        echo \$sampleid_stripped >> samplesheet.txt
      done
    """
}


