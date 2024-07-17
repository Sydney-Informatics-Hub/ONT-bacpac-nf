#!/usr/bin/env python3

#########################################################
#
# Platform: NCI Gadi HPC
#
# Author: Nandan Deshpande
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

import re
import os
import sys

# Description: A script which reads AMR results and creates a gene presence/absence matrix for heatmap
def parse_amrfinderplus_result(each_amrfinderplus,sampleID_details_dic,geneSymbols_description_dic):
    """
    Parse the AMR results to create a sampleID details dictionary
    """
    #amrFileName="AMR/amrfinderplus/"+sampleID+".txt"
   
    
    sampleID_raw=str(each_amrfinderplus)
    if sampleID_raw.find("_REF_")!=-1:
        sampleID=sampleID_raw.split("_REF_")[0].strip()
    else:
        sampleID=sampleID_raw.split(".txt")[0].strip()


    file_amr=open("%s"%each_amrfinderplus)
    data_amr=file_amr.readlines()
    file_amr.close()

    geneSymbol_details_dic={}

    for each_amr_gene in data_amr[1:]:
        sp_line=each_amr_gene.split("\t")
        geneSymbol=sp_line[1].strip()
        description=sp_line[2].strip()
        geneSymbol_details_dic[geneSymbol]=description
        
        if geneSymbol not in geneSymbols_description_dic:
            geneSymbols_description_dic[geneSymbol]=description


    sampleID_details_dic[sampleID]=geneSymbol_details_dic

    out_array=[]
    out_array.append(sampleID_details_dic)
    out_array.append(geneSymbols_description_dic)

    return out_array


def create_gene_matrix_and_annotation_files(sampleID_species_table,sampleID_details_dic,geneSymbols_description_dic):
    """
    Write the presence/absence matrix for heatmap
    """

    file_out_matrix=open("amrfinderplus_output.txt","w")
    header="sampleID"
    for geneSymbol in geneSymbols_description_dic.keys():
        header=header+"\t"+geneSymbol
    file_out_matrix.write("%s\n"%header)

    # Get a dictionary relating sampleID to dominant species - to be added to heatmap rowname
    file_sampleID_species=open("%s"%sampleID_species_table)
    data_sampleID_species=file_sampleID_species.readlines()
    file_sampleID_species.close()
    sampleID_species_dic={}

    for each_sampleID in data_sampleID_species[1:]:
        sp_sampleID_species=each_sampleID.split("\t")
        sampleID=sp_sampleID_species[0].strip()
        species=sp_sampleID_species[1].replace("\n","").strip()
        sampleID_species_dic[sampleID]=species


    for sampleID in sampleID_details_dic:
        if sampleID not in sampleID_species_dic:
            out_string=sampleID
        else:
            out_string=sampleID+" ("+sampleID_species_dic[sampleID].replace("_"," ")+")"
        
        present_sampleID_details=sampleID_details_dic[sampleID]
        for geneSymbol in geneSymbols_description_dic.keys():
            if geneSymbol in present_sampleID_details:
                out_string=out_string+"\t"+"1"
            else:
                out_string=out_string+"\t"+"0"

        file_out_matrix.write("%s\n"%out_string)

    file_out_matrix.close()

    """
    Write the gene Annotations file
    """

    file_out_annotation=open("amrfinderplus_output_GeneAnnotations.txt","w")

    header="geneName\tDescription"
    file_out_annotation.write("%s\n"%header)

    for geneSymbol in geneSymbols_description_dic.keys():
        out_string=geneSymbol+"\t"+geneSymbols_description_dic[geneSymbol]
        file_out_annotation.write("%s\n"%out_string)

    file_out_annotation.close()

    return


def main():

    all_args=sys.argv[1:]
    amrfinderplus_files=all_args[:len(all_args)-1]
    sampleID_species_table=all_args[len(all_args)-1]

    # Create a dictionary 
    sampleID_details_dic={}
    # Get a cumulative list of all gene symbols in the experiment for the final table matrix
    geneSymbols_description_dic={}

    # Iterate over each amrfinderplus output
    for each_amrfinderplus in amrfinderplus_files:
        out_array=parse_amrfinderplus_result(each_amrfinderplus,sampleID_details_dic,geneSymbols_description_dic)
        sampleID_details_dic=out_array[0]
        geneSymbols_description_dic=out_array[1]


    create_gene_matrix_and_annotation_files(sampleID_species_table,sampleID_details_dic,geneSymbols_description_dic)

    return

main()
