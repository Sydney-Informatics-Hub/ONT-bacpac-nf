## User guide: NCI Gadi execution

* [Quickstart for testing](#quickstart-repository-testing)
* [Set up the repository](#set-up)
* [Obtain a copy of your input data](#obtain-required-input-files)
* [Execute the workflow](#execute-the-workflow)
* [Monitor your execution](#monitor-your-execution)
* [Examine the results](#examine-the-results)
* [Troubleshooting errors](#troubleshooting-errors)

### Setting up the workspace 

To set up the workspace for the pipeline, first navigate to a suitable working directory and clone the GitHub repository. We suggest working on your project's scratch space on Gadi. In the following examples, we use the bash variable `${PROJECT}`, which refers to your default Gadi project. If you wish to use a different project ID, replace `${PROJECT}` with that ID; e.g. `cd /scratch/ab01`:

```bash
cd /scratch/${PROJECT}
WORK_DIR=my_experiment  # This will be your working directory; you can name this whatever you like
mkdir ${WORK_DIR}
cd ${WORK_DIR}
```

```bash
git clone https://github.com/Sydney-Informatics-Hub/ONT-bacpac-nf.git
```

To start the pipeline and keep it running even when you are disconnected from Gadi, you can set up a [persistent session](https://opus.nci.org.au/display/Help/Persistent+Sessions). Run the following command, providing your project code and a name for the session:

```bash
NAME=bacpac  # Name this whatever you like
persistent-sessions start  -p ${PROJECT} ${NAME}
```

You'll see an ssh command provided on the screen. Enter the session by running that command. For example:

```bash
ssh ${NAME}.${USER}.${PROJECT}.ps.gadi.nci.org.au
```

You'll need to navigate back to the directory where you have cloned the repository. For example: 

```bash
cd /scratch/${PROJECT}/${WORK_DIR}/ONT-bacpac-nf
```

---

**NOTE ON PERSISTENT SESSIONS**

You can check the status of your persistent session by running the following command: 

```bash
persistent-sessions list
```

FYI - you can stop your persistent session by running the following command: 

```bash
persistent-sessions kill <uuid>
```

To determine the UUID of the session you want to kill, use the list command as documented above.

---

### Obtain required input files

First, make a directory for your raw data files: 

```bash
mkdir data
```

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

```csv
barcode,sample,batch,file_path,sequencing_summary
barcode01,sample01,batch1,/path/to/dataset/barcode01,/path/to/dataset/sequencing_summary_batch1.txt
barcode02,sample02,batch1,/path/to/dataset/barcode02,/path/to/dataset/sequencing_summary_batch1.txt
barcode03,sample03,batch2,/path/to/dataset/barcode03.zip,/path/to/dataset/sequencing_summary_batch2.txt
barcode04,sample03,batch2,/path/to/dataset/barcode04.zip,/path/to/dataset/sequencing_summary_batch2.txt
```

See [Getting Started](./getting-started.md#samplesheet-method-preferred) for more details on the samplesheet structure. Also see three examples of samplesheet structures in the `assets` directory:
- [A simple samplesheet with one batch and one library/barcode per sample](../assets/samplesheet.simple.csv)
- [A single-batch samplesheet with three samples and four libraries/barcodes](../assets/samplesheet.single_batch.csv)
- [A multi-batch samplesheet with three samples and four libraries/barcodes](../assets/samplesheet.multi_batch.csv)

**Note:** The samplesheet structure has evolved since earlier versions of thispipeline. Please make sure that your samplesheet structure matches those in the examples.

### Preparing Singularity

This workflow executes different tools for each step as containers. This means you do not have to download and install anything before executing the pipeline. Containers are stored within a cache directory that depends upon your Gadi project and username: `/scratch/<PROJECT>/<USER>/.nextflow/singularity`. Your username will be automatically detected, but can be overridden with the `--gadi_user` parameter when running the pipeline. Your Gadi project will also be automatically detected, but can also be overridden with the `--gadi_account` parameter, as detailed in [Getting Started - Execution on gadi](./getting-started.md#execution-on-gadi). If a container doesn't exist in the cache directory, it will be automatically pulled during execution. Finally, you can override the default container cache directory with the `--singularityCacheDir` parameter.

You will also need to set the `SINGULARITY_CACHEDIR` environment variable. This tells Singularity to use this directory temporarily when pulling images. If this is not set, a directory in your home directory will be used and may run into storage quota limits.

```bash
export SINGULARITY_CACHEDIR=/scratch/${PROJECT}/${USER}/.singularity
```

To avoid having to reset this variable before each run, you can add the export command to your `~/.bashrc` file: 
  
```bash
# Add the following line to your .bashrc file
echo 'export SINGULARITY_CACHEDIR=/scratch/${PROJECT}/${USER}/.singularity' >> ~/.bashrc

# Reload your .bashrc file to apply the changes
source ~/.bashrc
```

### Execute the workflow

Two template run scripts have been provided in this repository at `example/run.*.gadi.sh`. One is for running the pipeline in the input directory mode (`example/run.input_dir.gadi.sh`), and the other is to run the pipeline using a samplesheet (`example/run.samplesheet.gadi.sh`).

The input directory version of the script looks like this:

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

# Load Nextflow and Singularity
module load nextflow/24.04.1
module load singularity

# Define inputs
input_directory=/path/to/input/directory  # TODO: Replace this with the path to your data
sequencing_summary=/path/to/sequencing_summary.txt  # TODO: Replace this with the path to your sequencing_summary_*.txt file from your ONT run
k2db=/path/to/kraken2/database  # TODO: Replace this with the path to your local copy of the Kraken2 database
gadi_account=${PROJECT}  # TODO: Change this if you want to use a project other than your default Gadi project
gadi_storage=scratch/${PROJECT}  # TODO: Change this if you want to use a different storage location on Gadi

nextflow run main.nf \
    --input_directory ${input_directory} \
    --sequencing_summary ${sequencing_summary} \
    --kraken2_db ${k2db} \
    --gadi_account ${gadi_account} \
    --gadi_storage ${gadi_storage} \
    -resume -profile gadi,high_accuracy  # NOTE: you can remove ',high_accuracy' if you want to run fast basecalling samples
```

The samplesheet version looks like this:

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

# Load Nextflow and Singularity
module load nextflow/24.04.1
module load singularity

# Define inputs
samplesheet=/path/to/samplesheet.csv  # TODO: Replace this with the path to your samplesheet
k2db=/path/to/kraken2/database  # TODO: Replace this with the path to your local copy of the Kraken2 database
gadi_account=${PROJECT}  # TODO: Change this if you want to use a project other than your default Gadi project
gadi_storage=scratch/${PROJECT}  # TODO: Change this if you want to use a different storage location on Gadi

nextflow run main.nf \
    --samplesheet ${samplesheet} \
    --kraken2_db ${k2db} \
    --gadi_account ${gadi_account} \
    --gadi_storage ${gadi_storage} \
    -resume -profile gadi,high_accuracy  # NOTE: you can remove ',high_accuracy' if you want to run fast basecalling samples
```

These scripts have several placeholder values that will need to be modified to suit your specific project requirements prior to running.

First, replace the placeholder string `<PROJECT>` within the header comment lines with your NCI project code:

```bash
#!/bin/bash
#PBS -P <PROJECT>
...
#PBS -l storage=scratch/<PROJECT>
```

Next, define the bash variables that will be passed to the pipeline parameters:

- `input_directory`: **Only for running from an _input directory_**. Set this to the path to your data.
- `sequencing_summary`: **Only for running from an _input directory_**. Set this to the path to your sequencing_summary_*.txt file from your ONT run
- `samplesheet`: **Only for running from a _samplesheet_**. Set this to the path to your samplesheet CSV file
- `k2db`: Set this to the path to your local copy of the Kraken2 database
- `gadi_account`: Change this line **only if** you want to use a project other than your default Gadi project
- `gadi_storage`:  Change this line **only if** you want to use a different storage location on Gadi

To execute the pipeline and observe its progress, please run **one** of the following commands.

To run the input directory version of the pipeline:

```bash
bash example/run.input_dir.gadi.sh
```

To run the samplesheet version of the pipeline:

```bash
bash example/run.samplesheet.gadi.sh
```

You can also submit the run script to the HPC scheduler with the `qsub` command:

```bash
qsub example/run.samplesheet.gadi.sh
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

* Singularity cache and tmp directories: these can fill up quickly and cause errors. Make sure to clean them out regularly. If your workflow fails and mentions it has run out of disk space or hit the inode limit, first delete the `tmp` directory in your base directory (where you run the workflow from) and try again. If that doesn't work, delete the singularity cache directory and the `tmp` directory that sits within the same directory as your cache directory and try again. 
