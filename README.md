# ONT-bacpac-nf

WIP title, WIP workflow. 

## Workflow description 

A rapid and portable workflow for pond-side sequencing of bacterial pathogens for sustainable aquaculture using ONT long-read sequencing. 

## User guide 

Dev execution: 

```bash 
module load singularity 
module load nextflow/24.04.1
```

```bash
bash test/run_test.sh
```

### Developer notes

Please use this structure for modules and saves these files as `run_process.nf`: 
```
process process_name {
  tag "ADD A TAG THAT CAPTURES TASK LEVEL INFO"
  container '<link to container>'

  input:
	//tuple val(barcode), path <input>

  output:
  path("*"), emit: process_out

  script: 
  """
  # EXPLAIN THE PROCESS 
  ADD CODE 
  """
}
```

## Component tools 

## Additional notes

## Help / FAQ / Troubleshooting

## License(s)

## Acknowledgements/citations/credits
