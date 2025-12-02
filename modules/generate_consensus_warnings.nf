process generate_consensus_warnings {
  tag "GENERATE WARNINGS FOR CONSENSUS SEQUENCE FAILURES"
  // No container because this runs basic bash code

  input:
  val failed_samples
  val consensus_method

  output:
  path 'failed_consensus_mqc.yaml', emit: mqc_yaml

  script:
  yaml_data = [
    'id: "failure_warnings"',
    'section_name: "Consensus Assembly Failure Warnings"',
    'description: "The following samples failed consensus assembly. For each of these samples, one of the de novo assemblies was chosen for downstream analyses."',
    'plot_type: "table"',
    'headers:',
    '  consensus_method:',
    '    title: "Consensus Assembly Method"',
    '  consensus_status:',
    '    title: "Status"',
    'data:'
  ]
  yaml_data += failed_samples.collect { x -> "  ${x}:\n    consensus_method: '${consensus_method}'\n    consensus_status: 'Fail'" }
  yaml_data = yaml_data.join('\n')
  """
  echo -e '${yaml_data}' > failed_consensus_mqc.yaml
  """
}
