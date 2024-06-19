# ONT-bacpac-nf

:wrench: THIS PIPELINE IS UNDER ACTIVE DEVELOPMENT :wrench:

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

Ensure you use the following when contributing to this code base 
* Break down tasks into modules, with distinct functions
* Clearly define input and output channels with descrptive names 
* Add comments within your code to explain the logic and purpose of complex sections
* Use configuration files to manage parameters, separating code from configuration
* Provide sensible default values 
* Design modules to fail early if prerequisites are not met or if an error occurs 
* Implement comprehensive Groovy [logging](https://www.sentinelone.com/blog/getting-started-quickly-groovy-logging/) with `log.info`
* Specify resource requirements for each process 
* Use dynamic resource handling to adjust resource requests based on input data size, where possible 
* Use Singularity containers
* Exploit parallelism by designing processes to run concurrently wherever possible 
* Consult the [benchmarking results](https://unisyd.sharepoint.com/:x:/r/teams/SydneyInformaticsHub2/Shared%20Documents/1%20SIH%20Central%20Document%20Repository/Projects/1%20JIRA%20projects/PIPE-4747%20Francisca%20Samsing%20-%20Genomics%20in%20a%20backpack/benchmarks.xlsx?d=w5d9c945ea94248d796ee4d816de39d01&csf=1&web=1&e=nmOpmZ) to optimise process resource requirements

Please use this structure for modules and saves these files as `run_process.nf`: 
```
process process_name {
  tag "ADD A TAG THAT CAPTURES TASK LEVEL INFO"
  container '<link to container>'

  input:
	tuple val(barcode), path <input>

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
