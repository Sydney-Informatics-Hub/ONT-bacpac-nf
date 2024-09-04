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
input_directory= #path to your input directory
samplesheet= #path to samplesheet file
k2db= #path to predownloaded kraken2 database
sequencing_summary= #path to sequencing summary file from ONT run 
gadi_account= #e.g. aa00
gadi_storage= #e.g. scratch/aa00 or scratch/aa00+scratch/bb11 for more than 1 storage space

# Unhash this command to run pipeline over whole directory
#nextflow run main.nf \
#	--input_directory ${input_directory} \
#	--kraken2_db ${k2db} \
#	--sequencing_summary ${sequencing_summary} \
#	--gadi_account ${gadi_account} \
#	--gadi_storage ${gadi_storage} \
#	-resume -profile gadi,high_accuracy #you can remove ,high_accuracy if you want to run fast basecalling samples

# Unhash this command to run pipeline with samplesheet
#nextflow run main.nf \
#	--samplesheet ${samplesheet} \
#	--kraken2_db ${k2db} \
#	--sequencing_summary ${sequencing_summary} \
#	--gadi_account ${gadi_account} \
#	--gadi_storage ${gadi_storage} \
#	-resume -profile gadi,high_accuracy #you can remove ,high_accuracy if you want to run fast basecalling samples
