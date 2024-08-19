## User guide: NCI Gadi execution

* [Set up the repository](#set-up)
* [Obtain a copy of your input data](#obtain-required-input-files)
* [Execute the workflow](#execute-the-workflow)
* [Monitor your execution](#monitor-your-execution)
* [Examine the results](#examine-the-results)
* [Troubleshooting errors](#troubleshooting-errors)

### Set up 

Navigate to your working directory on NCI Gadi: 

```bash
cd /scratch/<project>
```

Clone the repository and move into it: 

```bash
git clone https://github.com/Sydney-Informatics-Hub/ONT-bacpac-nf.git
cd ONT-bacpac-nf
```

Make a directory for your raw data files: 

```bash
mkdir data
```

### Obtain required input files 

Transfer your files to the working directory on Gadi from their original source: 

#### From your local machine  

Easiest way to transfer data between your local machine and an HPC is to use the FileZilla client. 

1. Go to the [Filezilla downloads page](https://filezilla-project.org/) and follow instructions to install on your computer
2. Open Filezilla and enter the following in the 'Host' field: sftp://gadi-dm.nci.org.au
3. Enter your username and password in the respective fields and click 'Quickconnect'
4. Navigate to the local site directory of choice
5. Navigate to the remote site directory of choice
6. To copy a file between local and remote, right click on the file and select 'Upload' or double click the file or drag and drop it to the desired location

#### From Sharepoint/OneDrive

Easiest way to transfer and deal with all the security settings for OneDrive/Sharepoint is to use Rclone. 

1. Go to the [Rclone downloads page](https://rclone.org/downloads/)
2. Right click on Intel/AMD - 64 bit and copy the link address 
3. Download using wget: 

```bash
wget https://downloads.rclone.org/v1.67.0/rclone-v1.67.0-linux-amd64.zip
```

4. Unzip the downloaded file:
  
```bash
unzip rclone-v1.67.0-linux-amd64.zip
```   

5. Move into the extracted directory: 

```bash
cd rclone-v1.67.0-linux-amd64
```

6. Copy the rclone binary to your bin directory, if you don't have one, create one: 

```bash
mkdir -p ~/bin
cp rclone ~/bin/
```

7. Add the bin directory to your PATH and reload your `.bashrc` to apply the changes:

```bash
echo 'export PATH=$HOME/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
```

8. Verify the installation: 

```bash 
rclone --version
```

9. Add an alias to your shell configuration file to make it easier to transfer files to Gadi: 

```bash
echo 'alias rclone="$HOME/bin/rclone"' >> ~/.bashrc
source ~/.bashrc
```

Once Rclone is installed, follow [these instructions](https://sydney-informatics-hub.github.io/tidbits/cli-transfer-to-onedrive.html) to configure your set up to transfer files from Sharepoint/OneDrive to Gadi. 

#### From RDS to Gadi

See scripts and instructions [here](https://github.com/Sydney-Informatics-Hub/Bio-toolkit/tree/main/Data-movement) for transferring files between RDS and Gadi.

### Prepare the samplesheet (optional)

If you would prefer to specify selected samples to run through this workflow you can use a samplesheet as input, rather than a directory. You can use it to specify which files you would like to process and can specify this choice in your run command with `--samplesheet` rather than `input_directory`. 

The samplesheet should be a CSV file with the following structure: 

| #barcode,batch,file_path                      |
| --------------------------------------------- |
barcode01,batch1,/path/to/dataset/barcode01.zip |
barcode03,batch2,/path/to/dataset/barcode03.zip |
barcode10,batch1,/path/to/dataset/barcode10.zip | 

See an example of a samplesheet [here](../assets/samplesheet.csv). Keep in mind your header will need to be the same as the example, including the prefixed hash (#). 

### Execute the workflow

This workflow executes different tools for each step as containers. This means you do not have to download and install anything before executing the pipeline. Containers will be pulled during execution. Allow Nextflow to download and save your containers to a cache directory: 

```bash
# Create the following cache directories for singularity containers
mkdir /scratch/<PROJECT>/singularity_cache
mkdir /scratch/<PROJECT>/nextflow_singularity_cache

# Set the cache directory as an environment variable
export SINGULARITY_CACHEDIR=/scratch/<PROJECT>/singularity_cache
export NXF_SINGULARITY_CACHEDIR=/scratch/<PROJECT>/nextflow_singularity_cache
```

Confirm that the cache directory has been set: 

```bash
echo $SINGULARITY_CACHEDIR
echo $NXF_SINGULARITY_CACHEDIR
```

To avoid having to reset this variable before each run, you could add the export command to your `.bashrc` file: 
  
```bash
# Add the following line to your .bashrc file
echo 'export NXF_SINGULARITY_CACHEDIR=/scratch/<PROJECT>/singularity_cache' >> ~/.bashrc

# Reload your .bashrc file to apply the changes
source ~/.bashrc
```

A template run script has been provided in this repository at `test/run_test.sh`. It will need to be modified to suit your specific project requirements.

Replace `<PROJECT>` with your project code in the following lines of the script: 

* `#PBS -P <PROJECT>`
* `#PBS -l storage=scratch/<PROJECT>`

Define paths to the workflow input variables: 

* `input_directory=/scratch/<PROJECT>/data` (option 1)
* `samplesheet=/scratch/<PROJECT>/data/samplesheet.csv` (option 2)
* `k2db=/scratch/<PROJECT>/databases/kraken2_db`
* `sequencing_summary=/scratch/<PROJECT>/data/sequencing_summary.txt`

This is the structure of the run script saved in `test/run_test.sh` on all files in a directory:

```bash
#!/bin/bash

#PBS -P <PROJECT> 
#PBS -l walltime=10:00:00
#PBS -l ncpus=1
#PBS -l mem=5GB
#PBS -W umask=022
#PBS -q copyq
#PBS -l wd
#PBS -l storage=scratch/<PROJECT>
#PBS -l jobfs=100GB

## RUN FROM PROJECT DIRECTORY: bash test/run_test.sh

# Load version of nextflow with plug-in functionality enabled 
module load nextflow/24.04.1 
module load singularity 

# Define inputs 
input_directory= #path to your input directory
samplesheet= #path to samplesheet
k2db= #path to predownloaded kraken2 database
sequencing_summary= #path to sequencing summary file from ONT run 

# Run pipeline 
nextflow run main.nf \
  --input_directory ${in} \
  --kraken2_db ${k2db} \
  --sequencing_summary ${sequencing_summary} \
  -resume 
```

This is the structure of the run script saved in `test/run_test.sh` on selected files specified in a samplesheet:

```bash
#!/bin/bash

#PBS -P <PROJECT> 
#PBS -l walltime=10:00:00
#PBS -l ncpus=1
#PBS -l mem=5GB
#PBS -W umask=022
#PBS -q copyq
#PBS -l wd
#PBS -l storage=scratch/<PROJECT>
#PBS -l jobfs=100GB

## RUN FROM PROJECT DIRECTORY: bash test/run_test.sh

# Load version of nextflow with plug-in functionality enabled 
module load nextflow/24.04.1 
module load singularity 

# Define inputs 
input_directory= #path to your input directory
samplesheet= #path to samplesheet
k2db= #path to predownloaded kraken2 database
sequencing_summary= #path to sequencing summary file from ONT run 

# Run pipeline 
nextflow run main.nf \
  --input_directory ${in} \
  --kraken2_db ${k2db} \
  --sequencing_summary ${sequencing_summary} \
  -resume 
```

To execute the pipeline and observe its progress, please run the following command: 

```bash
bash test/run_test.sh
```

You can also run the pipeline with the following command: 

```bash
qsub test/run_test.sh
```

### Monitor your execution

If you execute the pipeline using the bash method above, rather than the qsub method, progress updates will be printed to the screen. Many tasks run by this pipeline are executed as jobs by the job scheduler. If you'd like to track the progress of these jobs, you can run: 

```bash
qstat -Esw
```

### Examine the results

Results are currently output to the `results` directory. See [interpreting-results.md](./docs/interpreting-results.md) for a summary of the outputs. 

Intermediate files that are not of interest in downstream work but may be useful for troubleshooting are available in the `work/` directory. You can check which work directory corresponds to which process by looking at the `.trace.txt` file in `results/runInfo` directory. 

### Troubleshooting errors 

* Singularity cache and tmp directories: these can fill up quickly and cause errors. Make sure to clean them out regularly. If your workflow fails and mentions it has run out of disk space, first delete the `tmp` directory in your base directory (where you run the workflow from) and try again. 