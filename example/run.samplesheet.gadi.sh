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
