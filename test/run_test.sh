#!/bin/bash

#PBS -I
#PBS -P er01
#PBS -l walltime=4:00:00
#PBS -l ncpus=1
#PBS -l mem=6GB
#PBS -W umask=022
#PBS -q copyq
#PBS -l wd
#PBS -l storage=scratch/er01
#PBS -l jobfs=1GB

## RUN FROM PROJECT DIRECTORY WITH: bash test/run_test.sh

# Load version of nextflow with plug-in functionality enabled 
module load nextflow/24.04.1 
module load singularity 

# Define inputs 
dir="/scratch/er01/fj9712/ONT-bacpac-nf_wt/issue-21" #path to your input directory
in="${dir}/data" #path to your input directory
k2db="${in}/kraken2_db" #path to predownloaded kraken2 database
sequencing_summary="${in}/sequencing_summary_FAX78092_2830cc58_163c38f4.txt" #path to sequencing summary file from ONT run 
gadi_account="er01" #e.g. aa00
gadi_storage="scratch/er01" #e.g. scratch/aa00

# Unhash this command to run pipeline over whole directory
#nextflow run main.nf \
#	--input_directory ${input_directory} \
#	--kraken2_db ${k2db} \
#	--sequencing_summary ${sequencing_summary} \
#	--gadi_account ${gadi_account} \
#	--gadi_storage ${gadi_storage} \
#	-resume 

# Unhash this command to run pipeline with samplesheet
samplesheet="${in}/samplesheet.csv" #path to samplesheet
nextflow run main.nf \
	--samplesheet ${samplesheet} \
	--kraken2_db ${k2db} \
	--sequencing_summary ${sequencing_summary} \
	--gadi_account ${gadi_account} \
	--gadi_storage ${gadi_storage} \
	-resume 
