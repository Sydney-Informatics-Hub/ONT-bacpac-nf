process parse_required_pycoqc_segments {
  tag "PARSE REQUIRED PYCOQC PLOTS from pycoqc output"  
  //container 'depot.galaxyproject.org/singularity/python:3.8.3'

  input:
        path(complete_pycoqc_output)
        path(pycoqc_header_file)

  output:
  	path("pycoQC_mqc.html"), emit: pycoQC_mqc

  script: 
  """
  parse_required_pycoqc_segments.py \\
    ${complete_pycoqc_output} \\
    ${pycoqc_header_file}
  """
}
