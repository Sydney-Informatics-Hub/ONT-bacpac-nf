#!/bin/bash

#PBS -P tj48 
#PBS -l walltime=04:00:00
#PBS -l ncpus=1
#PBS -l mem=5GB
#PBS -W umask=022
#PBS -q copyq
#PBS -l wd
#PBS -l storage=gdata/er01+scratch/er01
#PBS -l jobfs=100GB

## RUN FROM PROJECT DIRECTORY
## BEFORE RUNNING, INITIATE INTERACTIVE SESSION: 
#### qsub -I -P tj48 -q normal -lmem=190gb,ncpus=48,storage=scratch/er01+scratch/tj48

# Load version of nextflow with plug-in functionality enabled 
module load nextflow/24.04.1 
module load singularity 

export SINGULARITY_CACHEDIR=/scratch/er01/ndes8648/pipeline_work/nextflow/TMPDIR_PATH


# Define inputs 
#in=/scratch/er01/gs5517/workflowDev/ONT-bacpac-nf/dataset/testing
in=/scratch/er01/ndes8648/pipeline_work/nextflow/PIPE-4747/github_repos/debug/data
k2db=/scratch/er01/gs5517/workflowDev/ONT-bacpac-nf/test/kraken2_db

multiqc=/scratch/er01/ndes8648/pipeline_work/nextflow/PIPE-4747/github_repos/debug/ONT-bacpac-nf/multiqc_config.yml


# Run pipeline 
nextflow run main.nf \
  --input ${in} \
  --kraken2_db ${k2db} \
  -resume \
  --multiqc_config ${multiqc}
