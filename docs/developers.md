
## Developer notes

Fast, iterative testing is best done within an interactive session on Gadi. Start an interactive session with the following command: 

```bash
qsub -I -P <PROJECT> -lwalltime=2:00:00 -lmem=190GB -lncpus=24 -qnormal -lstorage=scratch/<PROJECT>
```

Once the session starts, you'll need to move back to your `ONT-bacpac-nf` directory. Execute the pipeline with:

```bash
bash test/run_test.sh
```

Keep in mind: 
* No external network access on job queues, except copyq 
* Downloading kraken2 database is currently slowest step, so its best to download once and reuse it by providing the `--kraken2_db` parameter to the pipeline
* Will explore faster and more secure download method for all reference datasets with [aria2](https://hpc.nih.gov/apps/aria2.html )

Ensure you do the following: 
* Break down tasks into modules, with distinct functions
* Clearly define input and output channels with descrptive names 
* Add comments within your code to explain the logic and purpose of complex sections
* Use configuration files to manage parameters, separating code from configuration
* Provide sensible default values 
* Design modules to fail early if prerequisites are not met or if an error occurs 
* Implement comprehensive Groovy [logging](https://www.sentinelone.com/blog/getting-started-quickly-groovy-logging/) with `log.info`
* Specify resource requirements for each process 
* Use dynamic resource handling to adjust resource requests based on input data size, where possible 
* Use Singularity to excecute biocontainers or Wave containers
* Exploit parallelism by designing processes to run concurrently wherever possible 
* Consult the [benchmarking results](https://unisyd.sharepoint.com/:x:/r/teams/SydneyInformaticsHub2/Shared%20Documents/1%20SIH%20Central%20Document%20Repository/Projects/1%20JIRA%20projects/PIPE-4747%20Francisca%20Samsing%20-%20Genomics%20in%20a%20backpack/benchmarks.xlsx?d=w5d9c945ea94248d796ee4d816de39d01&csf=1&web=1&e=nmOpmZ) to optimise process resource requirements

Please use this structure for modules and saves these files as `run_process.nf`: 
```
process process_name {
  tag "ADD A TAG THAT CAPTURES TASK LEVEL INFO"
  container '<link to container>'

  input:
	tuple val(sample), path <input>

  output:
  path("*"), emit: process_out

  script: 
  """
  # EXPLAIN THE PROCESS 
  ADD CODE 
  """
}
```
