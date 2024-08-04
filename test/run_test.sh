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
module load R/4.3.1

# Define inputs 
#in= #path to your input directory
#k2db= #path to predownloaded kraken2 database
#sequencing_summary= #path to sequencing summary file from ONT run 
#gadi_account= #e.g. aa00
#gadi_storage= #e.g. scratch/aa00

# Run pipeline 
nextflow run main.nf \
	--input ${in} \
	--kraken2_db ${k2db} \
	--sequencing_summary ${sequencing_summary} \
	--gadi_account ${gadi_account} \
	--gadi_storage ${gadi_storage} \
	-resume 
