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

import os
import sys
import subprocess
import glob

# Retrieve command-line arguments
sample_id = sys.argv[1]
number_of_assemblers = 2


def get_contigs_clusters(data_clusters,number_of_assemblies):
    """
    Categorise trycycler clusters such that only a particular category with single copy 
    contig representation from all assemblers is marked for reconciliation step
    """

    each_cluster=data_clusters.split("_cluster")

    for every_cluster in each_cluster[1:]:
        cluster_id_array=[]
        sp_cluster_lines=every_cluster.split("\n")
        cluster_id=sp_cluster_lines[0].split("/")[1].strip()

        unique_cluster_ids=[]

        for each_entry in sp_cluster_lines[1:]:
            entry_now=each_entry.replace("\n","").strip()
            if entry_now!="" and entry_now.find(".fasta")!=-1:
                cluster_id_array.append(entry_now)
                
                assemblyID=entry_now.split("_")[0].strip()
                if assemblyID not in unique_cluster_ids:
                    unique_cluster_ids.append(assemblyID)

        # CASE 1 (Avoid): If contig entries from same assembly are present in a cluster - multiple times, sugests possible fragments / mis-assemblies etc
        if len(unique_cluster_ids) < len(cluster_id_array):
            mkdir_folder="mkdir -p "+sample_id+"_discarded"
            os.system(mkdir_folder)

            mv_contigs_discarded="cp -r "+sample_id+"_cluster/"+cluster_id+" " +sample_id+"_discarded/"
            os.system(mv_contigs_discarded)
        
        # CASE 2 (Good) : If a contig is assembled by both assemblers, one contig per assembler 
        elif len(cluster_id_array) == int(number_of_assemblies):
            mkdir_folder="mkdir -p "+sample_id+"_for_reconciliation/"
            os.system(mkdir_folder)
            
            mv_good_contigs="cp -r "+sample_id+"_cluster/"+cluster_id+" " +sample_id+"_for_reconciliation/"
            os.system(mv_good_contigs)

        # CASE 3 (Avoid): One or more assemblers have no contig representation in the cluster
        elif len(cluster_id_array) < (int(number_of_assemblers)):
            mkdir_folder="mkdir -p "+sample_id+"_discarded/"
            os.system(mkdir_folder)

            mv_contigs_discarded="cp -r "+sample_id+"_cluster/"+cluster_id+" "+sample_id+"_discarded/"
            os.system(mv_contigs_discarded)

        # CASE 4 (Avoid): Single contig cluster
        elif len(cluster_id_array)==1:
            mkdir_folder="mkdir -p results/"+sample_id+"_discarded/"
            os.system(mkdir_folder)

            mv_contigs_discarded="cp -r "+sample_id+"_cluster/"+cluster_id+" "+sample_id+"_discarded/"
            os.system(mv_contigs_discarded)
    
    return 


def main():
    number_of_assemblies=number_of_assemblers

    # Generate cluster detail files for downstream 
    out_cluster_flag=sample_id+"_cluster/cluster_flag_file.txt"
    cluster_list_string="ls "+sample_id+"_cluster/cluster_*/1_contigs/"+ " > "+sample_id+"_cluster/cluster_list.txt"
    os.system(cluster_list_string)

    cluster_list_file_name=sample_id+"_cluster/cluster_list.txt"
    file_clusters=open("%s"%cluster_list_file_name)
    data_clusters=file_clusters.read()
    file_clusters.close()

    # Categorise the trycycler clusters 
    get_contigs_clusters(data_clusters,number_of_assemblies)

    sys.exit(0)

    return

main()
