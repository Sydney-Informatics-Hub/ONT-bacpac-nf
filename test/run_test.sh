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

# Define inputs 
in=/scratch/er01/gs5517/workflowDev/ONT-bacpac-nf/dataset/testing

# Run pipeline 
nextflow run main.nf \
  --input ${in} \
  -resume