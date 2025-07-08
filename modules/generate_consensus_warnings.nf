process generate_consensus_warnings {
  tag "GENERATE WARNINGS FOR CONSENSUS SEQUENCE FAILURES"
  // No container because this runs basic bash code

  input:
  val failed_barcodes
  val consensus_method

  output:
  path 'failed_consensus_mqc.yaml', emit: mqc_yaml

  script:
  yaml_data = [
    'id: "failure_warnings"',
    'section_name: "Failure Warnings"',
    'description: "The following samples failed consensus assembly."',
    'plot_type: "table"',
    'headers:',
    '  consensus_method:',
    '    title: "Consensus Assembly Method"',
    '  consensus_status:',
    '    title: "Status"',
    'data:'
  ]
  yaml_data += failed_barcodes.collect { x -> "  ${x}:\n    consensus_method: '${consensus_method}'\n    consensus_status: 'Fail'" }
  yaml_data = yaml_data.join('\n')
  """
  echo -e '${yaml_data}' > failed_consensus_mqc.yaml
  """
}
