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

# Description: A script used in the module to create phylogeny tree, to get dominant species for each sample

import os
import sys
import glob
import shutil


def get_dominant_species(sampleID,present_sampleid_k2path,sampleID_species_dic,nr_species_list):
    """
    Get the dominant species name from kraken2 report 
    """

    #file_path=sampleID+".k2report"
    file_path=present_sampleid_k2path
    file_in=open("%s"%file_path)
    data_in=file_in.readlines()
    file_in.close()

    most_dominent=0
    species=""
    for eachLine in data_in:
        sp1=eachLine.split("\t")

        # taxaColumn was placed in  column 5 for brcodes 01/
        taxaColumn=sp1[5].strip()


        if taxaColumn!="S":
            continue
        taxa_percent=float(sp1[0].strip())
        taxa_name=sp1[7].replace("\n","").strip()

        
        if taxa_percent>most_dominent:
            most_dominent=taxa_percent
            species=taxa_name


    if species not in nr_species_list and species!="":
        nr_species_list.append(species)

    if most_dominent!=0:
        sampleID_species_dic[sampleID]=species.replace(" ","_")

    return sampleID_species_dic



def get_available_species_genome_details_dic(assembly_summary_refseq,species_name,species_name_abbreviation):
    """
    Download protein fasta files for a complete reference geneome
    """
    species_name_noSpaces=species_name.replace(" ","_").strip()

    species_name_for_grep=species_name.replace("_"," ").strip()
    # Pick up Complete Genomes
    #grep_species_lines="grep '"+species_name+"' reference/assembly_summary_refseq.txt"+" |grep 'Complete Genome' > temp_specific_species.txt"
    grep_species_lines="grep '"+species_name_for_grep+"' "+assembly_summary_refseq+" |grep 'Complete Genome' > temp_specific_species.txt"

    # Update: Pick up the single "representative genome"
    #grep_species_lines="grep '"+species_name+"' reference/assembly_summary_refseq.txt"+" |grep 'representative genome' > temp_specific_species.txt"

    os.system(grep_species_lines)

    input_file_name="temp_specific_species.txt"
    file_in=open("%s"%input_file_name)
    data_in=file_in.readlines()
    file_in.close()

    for each_asembly in data_in[:1]:
        sp_assembly=each_asembly.split("\t")
        assembly_id=sp_assembly[0].strip()
        species_name_noSpaces=species_name.replace(" ","_").strip()

        ftp_base_string=sp_assembly[19].strip()
        additional_id=sp_assembly[15].strip()

        protein_file_name=assembly_id+"_"+additional_id+"_protein.faa.gz"

        ftp_string="wget -P phylogeny/"+" "+ftp_base_string+"/"+protein_file_name
        os.system(ftp_string)

        sleep_string="sleep 10"
        os.system(sleep_string)

        protein_file_name_final=species_name_noSpaces+"_REF_"+protein_file_name.replace("_protein","").strip()
        rename_string="mv phylogeny/"+protein_file_name+" phylogeny/"+protein_file_name_final
        os.system(rename_string)

        gunzip_string="gunzip phylogeny/"+protein_file_name_final
        os.system(gunzip_string)


        # ftp string for genome assembly file (abricate)
        genomic_file_name=assembly_id+"_"+additional_id+"_genomic.fna.gz"

        ftp_string="wget -P phylogeny/"+" "+ftp_base_string+"/"+genomic_file_name
        os.system(ftp_string)

        sleep_string="sleep 10"
        os.system(sleep_string)

        genomic_file_name_final=species_name_noSpaces+"_REF_"+genomic_file_name.replace("_genomic","").strip()
        rename_string="mv phylogeny/"+genomic_file_name+" phylogeny/"+genomic_file_name_final
        os.system(rename_string)

        gunzip_string="gunzip phylogeny/"+genomic_file_name_final
        os.system(gunzip_string)

    return




def main():

    #kraken2_reports = sys.argv[1:]
    
    assembly_summary_refseq=sys.argv[1]
    all_args=sys.argv[2:]
    len_args=len(all_args)
    half_way=int(len_args/2)

    kraken2_reports=all_args[:half_way]
    bakta_results=all_args[half_way:]

    file_tt=open("tt.txt","w")
    for i in range(0,len(all_args)):
        paths=all_args[i]
        file_tt.write("%s\n"%paths)
    
    file_tt.write("%s"%half_way)
    file_tt.write("%s"%kraken2_reports)


    #file_tt.close()

    #return


    # (1) Create sample id - top species table 
    sampleID_species_dic={}

    # generate a non-redundant list of all species identified in the run
    nr_species_list=[]
                
    for each_sample in range(0,len(kraken2_reports)):
        present_sampleid_k2path=kraken2_reports[each_sample]
        present_sampleid=str(present_sampleid_k2path).split('/')[-1].split('.')[0]
        # Species provided to pipeline input
        sampleID_species_dic=get_dominant_species(present_sampleid,present_sampleid_k2path,sampleID_species_dic,nr_species_list)

    output_sampleID_species_table_path="sampleID_species_table_mqc.txt"
    file_out=open("%s"%output_sampleID_species_table_path,"w")
    header="sampleID\tSpecies"
    file_out.write("%s\n"%header)
    
    # Write sampleID \t dominant-species to a file sampleID_species_table_mqc.txt
    for eachSampleID in sampleID_species_dic:
        out_string=eachSampleID+"\t"+sampleID_species_dic[eachSampleID]
        file_out.write("%s\n"%out_string)

    file_out.close()


    # (2) Copy bakta protein files to a new 'phylogeny' folder for orthofinder
    mkdir_phylogeny_dir="mkdir -p phylogeny"
    os.system(mkdir_phylogeny_dir)

    for each_sample in range(0,len(bakta_results)):
        present_sampleid_baktapath=bakta_results[each_sample]
        present_sampleid=str(present_sampleid_baktapath).split("_bakta")[0].strip()
        present_species=sampleID_species_dic[present_sampleid]

        final_protein_file_name=present_sampleid+"_"+present_species+".faa"

        find_and_cpy_cmd='find '+present_sampleid_baktapath+'/ -type f -name "*.faa" ! -name "*hypotheticals*.faa" -exec cp {} "phylogeny/"'+final_protein_file_name+' \;'
        #print("find_and_cpy_cmd",find_and_cpy_cmd)
        os.system(find_and_cpy_cmd)  

    # Get the unique list of all possible primary species in this run
    species_list=list(set(sampleID_species_dic.values()))


    # (3) Get Reference protein and genome-assembly fasta files 
    for species_name in species_list:
        file_tt.write("%s\n"%species_name)
        species_name_abbreviation_sp=species_name.split("_")
        species_name_abbreviation=species_name_abbreviation_sp[0][0].strip()+species_name_abbreviation_sp[1][0].strip()
        # Get a list of genomes with IDS for the species of interest 
        get_available_species_genome_details_dic(assembly_summary_refseq,species_name,species_name_abbreviation)
    
    file_tt.close()

    return

main()
