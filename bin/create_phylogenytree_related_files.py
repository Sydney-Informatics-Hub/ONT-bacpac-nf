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
import argparse
from pathlib import Path

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


def get_available_species_genome_details_dic(assembly_summary_refseq, species_name):
    """
    Download protein fasta files for a complete reference genome
    """
    species_name_noSpaces = species_name.replace(" ", "_").strip()
    species_name_for_grep = species_name.replace("_", " ").strip()
    
    grep_species_lines = f"grep '{species_name_for_grep}' {assembly_summary_refseq} | grep 'reference genome' > temp_specific_species.txt"
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
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--assembly_summary_refseq",
        required=True,
        help="Path to refseq_summary.txt"
    )
    parser.add_argument(
        "--bakta_sample_info",
        required=True,
        help="Path to bakta_sample_info.tsv containing prefix-sample-assembler mappings"
    )
    parser.add_argument(
        "--kraken2_reports",
        nargs='+',
        required=True,
        help="Paths to k2report files"
    )
    parser.add_argument(
        "--bakta_results",
        nargs='+',
        required=True,
        help="Paths to bakta result .faa files"
    )
    args = parser.parse_args()

    sampleID_species_dic = {}
    nr_species_list = []

    for k2_path in args.kraken2_reports:
        """
        Parse sample/barcode IDs from kraken 2 path inputs
        k2_path = "barcode10.k2report"
        """
        sample_id = '.'.join(k2_path.split('.')[0:-1])
        sampleID_species_dic = get_dominant_species(sample_id, k2_path, sampleID_species_dic, nr_species_list)

    output_sampleID_species_table_path = "barcode_species_table_mqc.txt"
    with open(output_sampleID_species_table_path, "w") as file_out:
        header = "sampleID\tSpecies"
        file_out.write(f"{header}\n")
        for eachSampleID in sampleID_species_dic:
            out_string = f"{eachSampleID}\t{sampleID_species_dic[eachSampleID]}"
            file_out.write(f"{out_string}\n")

    os.makedirs("phylogeny", exist_ok=True)

    # Get prefix - sample ID mappings
    with open(args.bakta_sample_info, 'r') as f:
        bakta_sample_info = f.readlines()

    bakta_sample_dict = {}
    for sample in bakta_sample_info:
        sample_split = sample.split('\t')
        prefix = sample_split[0]
        id = sample_split[1]
        bakta_sample_info[prefix] = id

    for bakta_path in args.bakta_results:
        """
        Move .faa files to the phylogeny/ folder
        """
        path = Path(bakta_path)
        file_name = path[0].name
        sample_prefix = '.'.join(file_name.split('.')[0:-1])
        sample_id = bakta_sample_dict[sample_prefix]
        present_species = sampleID_species_dic[sample_id]

        final_protein_file_name = f"{sample_id}_{present_species}.faa"

        cpy_cmd = f'cp {bakta_path} "phylogeny/{final_protein_file_name}"'
        os.system(cpy_cmd)

    species_list = list(set(sampleID_species_dic.values()))

    for species_name in species_list:
        get_available_species_genome_details_dic(args.assembly_summary_refseq, species_name)

    return

main()
