#!/bin/bash

#PBS -P tj48 
#PBS -l walltime=10:00:00
#PBS -l ncpus=1
#PBS -l mem=5GB
#PBS -W umask=022
#PBS -q copyq
#PBS -l wd
#PBS -l storage=scratch/tj48
#PBS -l jobfs=100GB

## RUN FROM PROJECT DIRECTORY WITH: bash test/run_test.sh

# Load version of nextflow with plug-in functionality enabled 
module load nextflow/24.04.1 
module load singularity 

# Define inputs 
#in= #path to your input directory
#k2db= #path to predownloaded kraken2 database
#sequencing_summary= #path to sequencing summary file from ONT run 
#gadi_account= #e.g. aa00
#gadi_storage= #e.g. scratch/aa00


#in=/scratch/er01/ndes8648/pipeline_work/nextflow/PIPE-4747/github_repos/debug/data
in=/scratch/tj48/fs9163/ONT-bacpac-nf/data
k2db=/scratch/er01/gs5517/workflowDev/ONT-bacpac-nf/test/kraken2_db

multiqc=/scratch/er01/ndes8648/pipeline_work/nextflow/PIPE-4747/github_repos/debug/ONT-bacpac-nf/multiqc_config.yml
sequencing_summary=/scratch/tj48/fs9163/ONT-bacpac-nf/data/sequencing_summary_FAX78092_2830cc58_163c38f4.txt
pycoqc_header_file_path=/scratch/er01/ndes8648/pipeline_work/nextflow/PIPE-4747/github_repos/debug/ONT-bacpac-nf/pycoqc_report_header.txt
gadi_account=tj48
gadi_storage=scratch/er01


# Run pipeline 
nextflow run main.nf \
	--input ${in} \
	--kraken2_db ${k2db} \
	--sequencing_summary ${sequencing_summary} \
	--gadi_account ${gadi_account} \
	--gadi_storage ${gadi_storage} \
	-resume 
