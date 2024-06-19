#!/usr/bin/env python3

#########################################################
# 
# Platform: NCI Gadi HPC
# Description: see https://https://github.sydney.edu.au/informatics/PIPE-4747-Genomics_In_A_Backpack
#
# Author/s: Nandan Deshpande
# nandan.deshpande@sydney.edu.au
#
# If you use this script towards a publication, please acknowledge the
# Sydney Informatics Hub (or co-authorship, where appropriate).
#
# Suggested acknowledgement:
# The authors acknowledge the scientific and technical assistance
# <or e.g. bioinformatics assistance of <PERSON>> of Sydney Informatics
# Hub and resources and services from the National Computational
# Infrastructure (NCI), which is supported by the Australian Government
# with access facilitated by the University of Sydney.
#
#########################################################

# Description: Based on Trycycler reconcilation step and estimated genome-size baseed on kraken2 classification, decide on "Concensus" or "Flye-only" approach

import os
import sys
from pathlib import Path

def get_species_GenomeSizePlusChrNumber_dic(species):
    
    ### Generate a dictionary with a reference bacterial species as key and genome-size and number of Chromosomes as value

    species_GenomeSizePlusChrNumber_dic={}

    # This file is the output of the process 'modules/get_ncbi.nf' 
    file_ncbi="ncbi_genome_lookup.txt"   
    file_ncbi=open("%s"%file_ncbi)
    data_ncbi=file_ncbi.readlines()
    file_in.close()

    for eachSpecies in data_in[1:]:
        sp1=eachSpecies.split("\t")
        species_name=sp1[0].replace('"','').replace("'","").strip()
        size=sp1[4].strip()
        chromosomes=sp1[5].strip()
        if species_name==species:
            species_GenomeSizePlusChrNumber_dic[species]=size
            return species_GenomeSizePlusChrNumber_dic
    return species_GenomeSizePlusChrNumber_dic

def get_dominant_species(sample_id):
    
    ### Using the kraken2 taxanomy report for a sample, identify the dominant taxa (species) with highest read % assigned to it

    file_path=sample_id+".k2report"
    file_in=open("%s"%file_path)
    data_in=file_in.readlines()
    file_in.close()

    most_dominent=0
    species=""
    for eachLine in data_in:
        sp1=eachLine.split("\t")
        taxaColumn=sp1[5].strip()

        if taxaColumn!="S":
            continue
        taxa_percent=float(sp1[0].strip())
        taxa_name=sp1[7].replace("\n","").strip()

        if taxa_percent>most_dominent:
            most_dominent=taxa_percent
            species=taxa_name

    return species

def get_all_chromosomal_contigs_using_GenomeSize(genomeSize,sample_id,species):
    
    ### Flye assembly: Iterate over the assembled genome to identify the contigs which represent chromsomes using reference genome sizes

    # This is from the output of flye assembly
    flye_assembly_file=sample_id+"_flye_assembly/assembly_info.txt"
    file_in=open("%s"%flye_assembly_file)
    data_in=file_in.readlines()
    file_in.close()

    accumulated_genome_size=0
    all_chromosoal_ctgs_accomodated_flag="0"
    chromosomal_contigs_array=[]

    for eachContig in data_in[1:]:
        if all_chromosoal_ctgs_accomodated_flag=="1":
            return chromosomal_contigs_array

        sp1=eachContig.split("\t")
        contigID=sp1[0].strip()
        length=float(sp1[1].strip())

        accumulated_genome_size=accumulated_genome_size+length

        if accumulated_genome_size>genomeSize:
            all_chromosoal_ctgs_accomodated_flag="1"
        chromosomal_contigs_array.append(contigID)


    return chromosomal_contigs_array

def which_chromosomalContigs_ConsensusOrFlye(chromosomal_contigs_array,sample_id):

    ### Identify if the Trycycler-consensus option can be pursued or do we need to fall back to using Flye-only assembly

    # Define the path
    path_to_check = sample_id+"_cluster"

    # List directories in the path
    directories = [d for d in os.listdir(path_to_check) if os.path.isdir(os.path.join(path_to_check, d))]

    # Filter directories that match the pattern "cluster_*"
    cluster_directories = [d for d in directories if d.startswith("cluster_")]

    # Sort the cluster directories
    cluster_directories.sort()

    cluster_contigs_array=[]
    clusterID_clusterContigs_dic={}

    # Check if the Reconcilation step has worked for individual clusters (i.e. a 2_all_seqs.fasta is generated)
    listA = cluster_directories
    if listA!=[]:
        for eachCluster in listA:
            for eachChrContig in chromosomal_contigs_array:

                check_fasta="grep '"+eachChrContig+"' "+sample_id+"_cluster/"+eachCluster+"/2_all_seqs.fasta"

                if os.system(check_fasta)==0:
                    cluster_contigs_array.append(eachChrContig)
                    clusterID_clusterContigs_dic[eachCluster]=eachChrContig
    else:
        print("NO trycycler_clusters")

    # Check if ALL chromosomal contigs (chromosomal_contigs_array) have been succesfully reconciled
        # Only then use - Consensus approach

    if chromosomal_contigs_array==cluster_contigs_array:
        which_CHR_flag="C"
    else:
        which_CHR_flag="F"

    out_array=[]
    out_array.append(clusterID_clusterContigs_dic)
    out_array.append(which_CHR_flag)

    return out_array

def make_final_clusters_folder(clusterID_clusterContigs_dic,sample_id):
    
    ### Move all non-chromsomal contigs to a separate directory
    
    # Define the path
    path_to_check = sample_id+"_cluster"

    # List directories in the path
    directories = [d for d in os.listdir(path_to_check) if os.path.isdir(os.path.join(path_to_check, d))]

    # Filter directories that match the pattern "cluster_*"
    cluster_directories = [d for d in directories if d.startswith("cluster_")]

    # Sort the cluster directories
    cluster_directories.sort()

    listA = cluster_directories
    

    # Create a folder sample_id+"_final containing the clusters to be carried forward 
    if listA!=[]:
        for eachCluster in listA:
            if eachCluster not in clusterID_clusterContigs_dic:

                mkdir_folder="mkdir -p "+sample_id+"_discarded"
                os.system(mkdir_folder)

                cp_cluster_cmd="cp "+sample_id+"_cluster/"+eachCluster+" "+sample_id+"_discarded"
                os.system(cp_cluster_cmd)

            else:
                # Make a folder and copy the  chromosomal clusters to it  
                mkdir_folder="mkdir -p "+sample_id+"_final"
                os.system(mkdir_folder)

                cp_cluster_cmd="cp "+sample_id+"_cluster/"+eachCluster+" "+sample_id+"_final"
                os.system(cp_cluster_cmd)

    # Check if there are clusters in the path after moving the non-chromosomal clusters
    cluster_directories = [d for d in directories if d.startswith("cluster_")]
    # Sort the cluster directories
    cluster_directories.sort()

    listB = cluster_directories

    if listB==[]:
        print("No clusters listB")

    return

def separate_ChrAndNonChr_FlyeContigs_toRun_independantAnnotations(sample_id,chromosomal_contigs_array):
    
    ### Separate the contigs which do not represent Chromsomes

    flye_assembly_file=sample_id+"_flye_assembly/assembly.fasta"
    file_in=open("%s"%flye_assembly_file)
    data_in=file_in.read()
    file_in.close()

    mkdirChrContigs_string="mkdir -p "+sample_id+"_flye_assembly/Chr_contigs"
    os.system(mkdirChrContigs_string)

    mkdirNonChrContigs_string="mkdir -p "+sample_id+"_flye_assembly/NonChr_contigs"
    os.system(mkdirNonChrContigs_string)

    each_fasta=data_in.split(">")
    for every_fasta in each_fasta[1:]:
        sp1=every_fasta.split("\n",1)
        idNow=sp1[0].replace("\n","").strip()

        fastaNow=sp1[1]
        out_string=">"+idNow+"\n"+fastaNow

        if idNow in chromosomal_contigs_array:
            file_out_name=sample_id+"_flye_assembly/Chr_contigs/"+idNow+".fasta"
            file_out=open("%s"%file_out_name,"w")
            file_out.write("%s"%out_string)
            file_out.close()
        else:
            file_out_name=sample_id+"_flye_assembly/NonChr_contigs/"+idNow+".fasta"
            file_out=open("%s"%file_out_name,"w")
            file_out.write("%s"%out_string)
            file_out.close()

    # Get only Flye Chromsomal contigs
    cat_string="cat "+sample_id+"_flye_assembly/Chr_contigs/contig_*.fasta > "+sample_id+"_flye_assembly/Chr_contigs/flyeChromosomes.fasta"
    os.system(cat_string)

    return

def filter_out_ChrContigs_fromFlye_infoFile(sample_id,chromosomal_contigs_array):

    ### Flye: Create an assembly info file for Chromosomal clusters

    FlyeInfo_fileName=sample_id+"_flye_assembly/assembly_info.txt"

    file_FlyeInfo=open("%s"%FlyeInfo_fileName)
    contigLines=file_FlyeInfo.readlines()
    file_FlyeInfo.close()

    FlyeInfoChrContigs_fileName=sample_id+"_flye_assembly/Chr_contigs/assembly_info.txt"
    file_out=open("%s"%FlyeInfoChrContigs_fileName,"w")

    header=contigLines[0].replace("\n","").strip()
    file_out.write("%s\n"%header)

    for eachContig in contigLines[1:]:
        sp1=eachContig.split("\t")
        contigIDNow=sp1[0].strip()
        if contigIDNow in chromosomal_contigs_array:
            file_out.write("%s"%eachContig)

    file_out.close()

    return

def main():

    """
    Input: 
    - kraken2 taxanomy report: modules/run_kraken2.nf 
    - Output folder from flye assembly: modules/run_flye.nf
    - sample_id+"_cluster": the trycluster cluster folder  carried forward from classify_trycycler_clusters.py 

    Output: 
    
    Consensus
    - which_CHR_flag=="C": sys.exit(0)
    - ${sample_id}_final: folder containing reconciled Chromosomal clusters: run_trycycler_MSA.sh  
    
    OR
    
    Flye
    - which_CHR_flag=="F":sys.exit(1)
    - ${sample_id}_flye_assembly/Chr_contigs: folder containing Flye assembly Chromosomal contigs: run_medaka_polishing_flyAssembly.sh 
    """

    sample_id = sys.argv[1]

    ### 1. Identify and separate out all contigs from clusters which add on to genome-size of a species
    # These are marked as chromosomal-contigs which are retained for downstream annotation.  

    # Retreive the most abundant species from kraken2
    species=get_dominant_species(sample_id)

    # Generate a dictionary with a reference bacterial species as key and "Genome-size with number-of-Chromosomes" as value
    species_GenomeSizePlusChrNumber_dic=get_species_GenomeSizePlusChrNumber_dic(species)

    # Use only ninety perecent of genome size to avoid additional (non-chromosomal) contigs to be included 
    genomeSize=float(species_GenomeSizePlusChrNumber_dic[species])*1000000 
    NinetyPercentGenomeSize=genomeSize-(genomeSize*0.1)

    # Identify chromosoml contigs from the assembly 
    chromosomal_contigs_array=get_all_chromosomal_contigs_using_GenomeSize(NinetyPercentGenomeSize,sample_id,species)

    # Check if chromosomal contigs pass reconcilation 
        # Yes: To continue with Trycycler 
        # No": Continue with Flye Chromosomes
    
    ### 2. Check if we need to follow the consensus assembly path or fall back to Flye-only assembly 
    
    # Decide whether Consensus or Flye
    out_array=which_chromosomalContigs_ConsensusOrFlye(chromosomal_contigs_array,sample_id)
    clusterID_clusterContigs_dic=out_array[0]
    which_CHR_flag=out_array[1]

    # Make a final folder with clusters to be carries for further analysis 
    make_final_clusters_folder(clusterID_clusterContigs_dic,sample_id)
        
    # Create independant fastas for all Chromosomal/non-chromosomal Flye assembly contigs 
    separate_ChrAndNonChr_FlyeContigs_toRun_independantAnnotations(sample_id,chromosomal_contigs_array)
    filter_out_ChrContigs_fromFlye_infoFile(sample_id,chromosomal_contigs_array)

    if which_CHR_flag=="C":
        sys.exit(0)
    else:
        sys.exit(1)

    return

main()
