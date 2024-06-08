#!/bin/bash

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