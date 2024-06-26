process check_input {
    tag "INPUT: ${input.fileName}"
    container 'https://depot.galaxyproject.org/singularity/python:3.8.3'

    input:
		path input
    
    output:
    path 'samplesheet.csv' , emit: samplesheet

    script: // This process runs ../bin/samplesheetchecker.py 
    // See example at: https://github.com/Sydney-Informatics-Hub/Parabricks-Genomics-nf/blob/main/bin/samplesheetchecker.py
    """
		samplesheetchecker.py \\
        $input \\
        samplesheet.csv
    """
}