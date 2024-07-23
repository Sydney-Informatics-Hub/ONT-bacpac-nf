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

## RUN FROM PROJECT DIRECTORY WITH: bash test/run_test.sh

# Load version of nextflow with plug-in functionality enabled 
module load nextflow/24.04.1 
module load singularity 

# Define inputs 
in= #path to your input directory
k2db= #path to predownloaded kraken2 database
multiqc_config= #path to multiqc config.yml
sequencing_summary= #path to sequencing summary file from ONT run 
pycoqc_header= #path to pycoQC header file .txt
gadi_account= #e.g. aa00
gadi_storage= #e.g. scratch/aa00

# Run pipeline 
nextflow run main.nf \
  --input ${in} \
  --kraken2_db ${k2db} \
  --multiqc_config ${multiqc_config} \
  --sequencing_summary ${sequencing_summary} \
  --pycoqc_header_file ${pycoqc_header} \
  --gadi_account ${gadi_account} \
  --gadi_storage ${gadi_storage} \
  -resume 