#!/usr/bin/env python3

import os
import sys
from pathlib import Path

def get_species_genome_size_plus_chr_number_dic(species, ncbi_lookup):
    species_GenomeSizePlusChrNumber_dic = {}
    file_ncbi = open(ncbi_lookup)
    data_ncbi = file_ncbi.readlines()
    file_ncbi.close()

    for eachSpecies in data_ncbi[1:]:
        sp1 = eachSpecies.split("\t")
        species_name = sp1[0].replace('"', '').replace("'", "").strip()
        size = sp1[4].strip()
        chromosomes = sp1[5].strip()
        if species_name == species:
            species_GenomeSizePlusChrNumber_dic[species] = size
            return species_GenomeSizePlusChrNumber_dic
    return species_GenomeSizePlusChrNumber_dic

def get_dominant_species(ncbi_lookup, sample_id, k2_report):
    file_in = open(k2_report)
    data_in = file_in.readlines()
    file_in.close()

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

    return species

def get_all_chromosomal_contigs_using_genome_size(genomeSize, sample_id, species, flye_assembly):
    flye_assembly_file = os.path.join(flye_assembly, "assembly_info.txt")
    file_in = open(flye_assembly_file)
    data_in = file_in.readlines()
    file_in.close()

    accumulated_genome_size = 0
    chromosomal_contigs_array = []

    for eachContig in data_in[1:]:
        sp1 = eachContig.split("\t")
        contigID = sp1[0].strip()
        length = float(sp1[1].strip())

        accumulated_genome_size += length

        if accumulated_genome_size > genomeSize:
            break
        chromosomal_contigs_array.append(contigID)

    return chromosomal_contigs_array

def which_chromosomal_contigs_consensus_or_flye(chromosomal_contigs_array, sample_id, reconciled_clusters_directory):
    if isinstance(reconciled_clusters_directory, str):
        cluster_directories = [reconciled_clusters_directory]
    else:
        cluster_directories = reconciled_clusters_directory

    cluster_directories.sort()

    cluster_contigs_array = []
    clusterID_clusterContigs_dic = {}

    for eachCluster in cluster_directories:
        for eachChrContig in chromosomal_contigs_array:
            check_fasta = f"grep '{eachChrContig}' {eachCluster}/2_all_seqs.fasta"
            print(f"Running command: {check_fasta}")  # Debug statement
            if os.system(check_fasta) == 0:
                cluster_contigs_array.append(eachChrContig)
                clusterID_clusterContigs_dic[eachCluster] = eachChrContig

    if set(chromosomal_contigs_array) == set(cluster_contigs_array):
        which_CHR_flag = "C"
    else:
        which_CHR_flag = "F"

    out_array = [clusterID_clusterContigs_dic, which_CHR_flag]
    return out_array

def make_final_clusters_folder(clusterID_clusterContigs_dic, sample_id, reconciled_clusters_directory):
    if isinstance(reconciled_clusters_directory, str):
        cluster_directories = [reconciled_clusters_directory]
    else:
        cluster_directories = reconciled_clusters_directory

    cluster_directories.sort()

    for eachCluster in cluster_directories:
        if eachCluster not in clusterID_clusterContigs_dic:
            mkdir_folder = f"mkdir -p {sample_id}_discarded"
            print(f"Running command: {mkdir_folder}")  # Debug statement
            os.system(mkdir_folder)

            cp_cluster_cmd = f"cp -r {eachCluster} {sample_id}_discarded"
            print(f"Running command: {cp_cluster_cmd}")  # Debug statement
            os.system(cp_cluster_cmd)
        else:
            mkdir_folder = f"mkdir -p {sample_id}_final"
            print(f"Running command: {mkdir_folder}")  # Debug statement
            os.system(mkdir_folder)

            cp_cluster_cmd = f"cp -r {eachCluster} {sample_id}_final"
            print(f"Running command: {cp_cluster_cmd}")  # Debug statement
            os.system(cp_cluster_cmd)

    return

def separate_ChrAndNonChr_FlyeContigs_toRun_independentAnnotations(sample_id, chromosomal_contigs_array):
    flye_assembly_file = f"{sample_id}_flye_assembly/assembly.fasta"
    file_in = open(flye_assembly_file)
    data_in = file_in.read()
    file_in.close()

    mkdirChrContigs_string = f"mkdir -p {sample_id}_flye_assembly/Chr_contigs"
    print(f"Running command: {mkdirChrContigs_string}")  # Debug statement
    os.system(mkdirChrContigs_string)

    mkdirNonChrContigs_string = f"mkdir -p {sample_id}_flye_assembly/NonChr_contigs"
    print(f"Running command: {mkdirNonChrContigs_string}")  # Debug statement
    os.system(mkdirNonChrContigs_string)

    each_fasta = data_in.split(">")
    for every_fasta in each_fasta[1:]:
        sp1 = every_fasta.split("\n", 1)
        idNow = sp1[0].replace("\n", "").strip()

        fastaNow = sp1[1]
        out_string = f">{idNow}\n{fastaNow}"

        if idNow in chromosomal_contigs_array:
            file_out_name = f"{sample_id}_flye_assembly/Chr_contigs/{idNow}.fasta"
            file_out = open(file_out_name, "w")
            file_out.write(out_string)
            file_out.close()
        else:
            file_out_name = f"{sample_id}_flye_assembly/NonChr_contigs/{idNow}.fasta"
            file_out = open(file_out_name, "w")
            file_out.write(out_string)
            file_out.close()

    cat_string = f"cat {sample_id}_flye_assembly/Chr_contigs/contig_*.fasta > {sample_id}_flye_assembly/Chr_contigs/flyeChromosomes.fasta"
    print(f"Running command: {cat_string}")  # Debug statement
    os.system(cat_string)

    return

def filter_out_ChrContigs_fromFlye_infoFile(sample_id, chromosomal_contigs_array):
    FlyeInfo_fileName = f"{sample_id}_flye_assembly/assembly_info.txt"

    file_FlyeInfo = open(FlyeInfo_fileName)
    contigLines = file_FlyeInfo.readlines()
    file_FlyeInfo.close()

    FlyeInfoChrContigs_fileName = f"{sample_id}_flye_assembly/Chr_contigs/assembly_info.txt"
    file_out = open(FlyeInfoChrContigs_fileName, "w")

    header = contigLines[0].replace("\n", "").strip()
    file_out.write(f"{header}\n")

    for eachContig in contigLines[1:]:
        sp1 = eachContig.split("\t")
        contigIDNow = sp1[0].strip()
        if contigIDNow in chromosomal_contigs_array:
            file_out.write(eachContig)

    file_out.close()

    return

def main():
    sample_id = sys.argv[1]
    reconciled_clusters_directory = sys.argv[2:-3]
    flye_assembly = sys.argv[-3]
    k2_report = sys.argv[-2]
    ncbi_lookup = sys.argv[-1]

    print(f"Sample ID: {sample_id}")  # Debug
    print(f"Reconciled Clusters Directory: {reconciled_clusters_directory}")  # Debug
    print(f"Flye Assembly: {flye_assembly}")  # Debug
    print(f"K2 Report: {k2_report}")  # Debug
    print(f"NCBI Lookup: {ncbi_lookup}")  # Debug

    species = get_dominant_species(ncbi_lookup, sample_id, k2_report)
    print(f"Dominant Species: {species}")  # Debug

    species_GenomeSizePlusChrNumber_dic = get_species_genome_size_plus_chr_number_dic(species, ncbi_lookup)
    print(f"Species Genome Size Plus Chr Number Dic: {species_GenomeSizePlusChrNumber_dic}")  # Debug

    genome_size = float(species_GenomeSizePlusChrNumber_dic[species]) * 1000000 
    ninety_percent_genome_size = genome_size - (genome_size * 0.1)
    print(f"Genome Size: {genome_size}, Ninety Percent Genome Size: {ninety_percent_genome_size}")  # Debug

    chromosomal_contigs_array = get_all_chromosomal_contigs_using_genome_size(ninety_percent_genome_size, sample_id, species, flye_assembly)
    print(f"Chromosomal Contigs Array: {chromosomal_contigs_array}")  # Debug

    out_array = which_chromosomal_contigs_consensus_or_flye(chromosomal_contigs_array, sample_id, reconciled_clusters_directory)
    clusterID_clusterContigs_dic = out_array[0]
    which_CHR_flag = out_array[1]
    print(f"Cluster ID Cluster Contigs Dic: {clusterID_clusterContigs_dic}, Which CHR Flag: {which_CHR_flag}")  # Debug

    make_final_clusters_folder(clusterID_clusterContigs_dic, sample_id, reconciled_clusters_directory)
    separate_ChrAndNonChr_FlyeContigs_toRun_independentAnnotations(sample_id, chromosomal_contigs_array)
    filter_out_ChrContigs_fromFlye_infoFile(sample_id, chromosomal_contigs_array)

    if which_CHR_flag == "C":
        sys.exit(0)
    else:
        sys.exit(1)

if __name__ == "__main__":
    main()
