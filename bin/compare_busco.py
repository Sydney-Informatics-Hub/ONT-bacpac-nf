#!/usr/bin/env python3

import argparse
import json
from typing import Tuple

def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "json_files",
        metavar="FILE",
        type=str,
        nargs="+",
        help="Paths to one or more BUSCO JSON files"
    )
    return parser.parse_args()

def get_complete_buscos(json_file) -> Tuple[str, float]:
    """
    Get the assembler name and complete BUSCO % from a json
    """
    with open(json_file, 'r') as f:
        j = json.load(f)
        assembler = j['parameters']['out']
        assembler = assembler.split('_')[0] # remove *_busco
        complete_busco = j['results']['Complete percentage']
        return assembler, complete_busco

if __name__ == "__main__":
    args = parse_args()
    results = [get_complete_buscos(file) for file in args.json_files]
    highest_busco = max(results, key=lambda x: x[1])
    print(highest_busco[0], end="") # don't print newline
