#!/usr/bin/env python3

"""
https://github.com/rrwick/Trycycler/wiki/Clustering-contigs#choose-your-clusters

Reads in the output of trycyclers clustering step to determine which clusters
are "good", and retained for downstream reconciliation steps.

Currently, the criteria for a good cluster is that it must contain:
    - One assembled contig from each assembler

A cluster is considered "bad" if it contains:
    - Contigs from a single assembler
    - Only a single contig
    - Many contigs (fragmented)

Outputs a simple text file with the clusters that should be reconciled.
Empty = none are suited for trycycler.
"""

import sys 
import glob
import re
from collections import defaultdict

def make_assembler_prefixes(num_assemblers: int) -> list:
    ords = range(65, 65 + num_assemblers) # chr(65) == "A", chr(66) = "B", ..
    return [ chr(o) for o in ords]

def parse_assemblies(input_dir: str) -> list:
    pattern = f"{input_dir}/cluster_**/1_contigs/**"
    contig_paths = glob.glob(pattern)
    contig_paths = [ re.sub(input_dir, "", p) for p in contig_paths ]
    contig_paths = [ re.sub(r"\.[^.]+$", "", p) for p in contig_paths ] # remove file ext
    return contig_paths

def catalog_clusters(contig_paths: list) -> defaultdict:
    results = defaultdict(list) # as >1 contig can come from the same assembler
    for path in contig_paths:
        cluster, assembler = path.split("/")[::2]
        assembler = re.sub("_.+", "", assembler) # Keep only the assembler e.g 'A', 'B', ..
        results[cluster].append(assembler)
    return results

def classify_clusters(results: defaultdict, assembly_prefixes: list) -> dict:
    dict = {}
    for cluster, assembler in results.items():
        dict[cluster] = "discard"
        if sorted(assembler) == assembly_prefixes:
            dict[cluster] = "reconcile"
    return dict 

def write_results(classification: dict) -> None:
    with open("clusters_to_reconcile.txt") as writer:
        for cluster, status in classification.items():
            if status == "reconcile":
                writer.write(cluster)

if __name__ == "__main__":

    cluster_path = sys.argv[1]
    
    NUM_ASSEMBLERS = 2
    assembler_prefixes = make_assembler_prefixes(NUM_ASSEMBLERS)

    contig_paths = parse_assemblies(cluster_path)
    results = catalog_clusters(contig_paths)
    classification = classify_clusters(results) 
    write_results(classification)