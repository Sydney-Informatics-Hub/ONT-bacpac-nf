#!/usr/bin/env python3

import sys
import gzip
import shutil
from pathlib import Path

def concatenate_and_gzip_files(input_files, output_file):
    """
    Concatenate and gzip the specified list of input files into the output file
    """
    with gzip.open(output_file, 'wb') as f_out:
        for input_file in input_files:
            print(f"Concatenating {input_file} into {output_file}")
            with gzip.open(input_file, 'rb') as f_in:
                shutil.copyfileobj(f_in, f_out)

def process_directory(subdir, output_dir):
    """
    Concatenate and gzip all .fastq.gz and .fq.gz files in the specified subdirectory
    """
    sample_name = subdir.name
    fastq_files = list(subdir.rglob('*.fastq.gz')) + list(subdir.rglob('*.fq.gz'))
    print(f"Detected fastq files in {subdir}: {[str(f) for f in fastq_files]}")
    if fastq_files:
        output_file = output_dir / f"{sample_name}_concat.fq.gz"
        concatenate_and_gzip_files(fastq_files, output_file)
        return output_file
    else:
        print(f"ERROR: No .fastq.gz or .fq.gz files found in {subdir}")
        return None

def main():
    if len(sys.argv) != 2:
        print("Usage: concatfq.py <subdirectory>")
        sys.exit(1)

    subdir = Path(sys.argv[1])
    output_dir = subdir.parent
    
    # Process the specified subdirectory
    process_directory(subdir, output_dir)

if __name__ == "__main__":
    main()
