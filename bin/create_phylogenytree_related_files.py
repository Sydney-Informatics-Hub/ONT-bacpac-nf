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
import urllib.request
import time


def download_file(url, output_path):
    try:
        with urllib.request.urlopen(url) as response:
            with open(output_path, 'wb') as out_file:
                shutil.copyfileobj(response, out_file)
        print(f"File downloaded successfully to {output_path}")
    except urllib.error.URLError as e:
        print(f"Failed to download file from {url}. Error: {e}")


def get_dominant_species(sampleID, present_sampleid_k2path, sampleID_species_dic, nr_species_list):
    """
    Get the dominant species name from kraken2 report 
    """
    file_path = present_sampleid_k2path
    with open(file_path) as file_in:
        data_in = file_in.readlines()

    most_dominant = 0
    species = ""
    for eachLine in data_in:
        sp1 = eachLine.split("\t")
        taxaColumn = sp1[5].strip()

        if taxaColumn != "S":
            continue
        taxa_percent = float(sp1[0].strip())
        taxa_name = sp1[7].replace("\n", "").strip()

        if taxa_percent > most_dominant:
            most_dominant = taxa_percent
            species = taxa_name

    if species not in nr_species_list and species != "":
        nr_species_list.append(species)

    if most_dominant != 0:
        sampleID_species_dic[sampleID] = species.replace(" ", "_")

    return sampleID_species_dic


def get_available_species_genome_details_dic(assembly_summary_refseq, species_name, species_name_abbreviation):
    """
    Download protein fasta files for a complete reference genome
    """
    species_name_noSpaces = species_name.replace(" ", "_").strip()
    species_name_for_grep = species_name.replace("_", " ").strip()
    
    grep_species_lines = f"grep '{species_name_for_grep}' {assembly_summary_refseq} | grep 'Complete Genome' > temp_specific_species.txt"
    os.system(grep_species_lines)

    input_file_name = "temp_specific_species.txt"
    with open(input_file_name) as file_in:
        data_in = file_in.readlines()

    for each_assembly in data_in[:1]:
        sp_assembly = each_assembly.split("\t")
        assembly_id = sp_assembly[0].strip()
        ftp_base_string = sp_assembly[19].strip()
        additional_id = sp_assembly[15].strip()

        protein_file_name = f"{assembly_id}_{additional_id}_protein.faa.gz"
        protein_url = f"{ftp_base_string}/{protein_file_name}"
        protein_output_path = f"phylogeny/{protein_file_name}"

        download_file(protein_url, protein_output_path)
        time.sleep(10)

        protein_file_name_final = f"{species_name_noSpaces}_REF_{protein_file_name.replace('_protein', '').strip()}"
        os.rename(protein_output_path, f"phylogeny/{protein_file_name_final}")

        gunzip_string = f"gunzip phylogeny/{protein_file_name_final}"
        os.system(gunzip_string)

        genomic_file_name = f"{assembly_id}_{additional_id}_genomic.fna.gz"
        genomic_url = f"{ftp_base_string}/{genomic_file_name}"
        genomic_output_path = f"phylogeny/{genomic_file_name}"

        download_file(genomic_url, genomic_output_path)
        time.sleep(10)

        genomic_file_name_final = f"{species_name_noSpaces}_REF_{genomic_file_name.replace('_genomic', '').strip()}"
        os.rename(genomic_output_path, f"phylogeny/{genomic_file_name_final}")

        gunzip_string = f"gunzip phylogeny/{genomic_file_name_final}"
        os.system(gunzip_string)

    return


def main():
    assembly_summary_refseq = sys.argv[1]
    all_args = sys.argv[2:]
    len_args = len(all_args)
    half_way = int(len_args / 2)

    kraken2_reports = all_args[:half_way]
    bakta_results = all_args[half_way:]

    sampleID_species_dic = {}
    nr_species_list = []

    for each_sample in range(len(kraken2_reports)):
        present_sampleid_k2path = kraken2_reports[each_sample]
        present_sampleid = str(present_sampleid_k2path).split('/')[-1].split('.')[0]
        sampleID_species_dic = get_dominant_species(present_sampleid, present_sampleid_k2path, sampleID_species_dic, nr_species_list)

    output_sampleID_species_table_path = "sampleID_species_table_mqc.txt"
    with open(output_sampleID_species_table_path, "w") as file_out:
        header = "sampleID\tSpecies"
        file_out.write(f"{header}\n")
        for eachSampleID in sampleID_species_dic:
            out_string = f"{eachSampleID}\t{sampleID_species_dic[eachSampleID]}"
            file_out.write(f"{out_string}\n")

    os.makedirs("phylogeny", exist_ok=True)

    for each_sample in range(len(bakta_results)):
        present_sampleid_baktapath = bakta_results[each_sample]
        present_sampleid = str(present_sampleid_baktapath).split("_bakta")[0].strip()
        present_species = sampleID_species_dic[present_sampleid]

        final_protein_file_name = f"{present_sampleid}_{present_species}.faa"

        find_and_cpy_cmd = f'find {present_sampleid_baktapath}/ -type f -name "*.faa" ! -name "*hypotheticals*.faa" -exec cp {{}} "phylogeny/{final_protein_file_name}" \\;'
        os.system(find_and_cpy_cmd)

    species_list = list(set(sampleID_species_dic.values()))

    for species_name in species_list:
        species_name_abbreviation_sp = species_name.split("_")
        species_name_abbreviation = f"{species_name_abbreviation_sp[0][0]}{species_name_abbreviation_sp[1][0]}"
        get_available_species_genome_details_dic(assembly_summary_refseq, species_name, species_name_abbreviation)

    return

main()
