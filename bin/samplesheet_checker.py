#!/usr/bin/env python3

import sys
import zipfile
import csv
from pathlib import Path

def check_file_path(file_path):
    """
    Check if the provided path is a valid file
    """
    if not Path(file_path).is_file():
        print(f"ERROR: {file_path} is not a valid file. Please check your provided input path.")
        sys.exit(1)

def unzip_file(zip_file, output_dir):
    """
    Unzip the specified .zip file into the output directory
    """
    with zipfile.ZipFile(zip_file, 'r') as zip_ref:
        zip_ref.extractall(output_dir)

def unzip_from_samplesheet(samplesheet_path, output_dir):
    """
    Unzip files based on the provided samplesheet.csv
    """
    output_dir.mkdir(exist_ok=True)

    # Read the samplesheet.csv
    with open(samplesheet_path, 'r') as csvfile:
        reader = csv.DictReader(csvfile)
        # Skip the '#' character from the header
        reader.fieldnames = [name.lstrip('#') for name in reader.fieldnames]
        
        for row in reader:
            zip_file = Path(row['file_path'])
            
            # Unzip the file into the batch directory
            unzip_file(zip_file, output_dir)

    print(f"Unzipping complete. Unzipped directories are organized by barcode and batch in {output_dir}")

def main():
    if len(sys.argv) != 3:
        print("Usage: inputchecker.py <samplesheet.csv> <output_directory>")
        sys.exit(1)

    samplesheet_path = Path(sys.argv[1])  # Ensure samplesheet_path is a Path object
    output_dir = Path(sys.argv[2])  # Ensure output_dir is a Path object
    
    # Check if samplesheet path is valid
    check_file_path(samplesheet_path)

    # Process files based on the samplesheet
    unzip_from_samplesheet(samplesheet_path, output_dir)

if __name__ == "__main__":
    main()
