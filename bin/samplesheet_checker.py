#!/usr/bin/env python3

import sys
import csv
from pathlib import Path

def check_file_path(file_path):
    """
    Check if the provided path is a valid file
    """
    if not Path(file_path).is_file():
        print(f"ERROR: {file_path} is not a valid file. Please check your provided input path.")
        sys.exit(1)

def check_files_exist(samplesheet_path):
    """
    Check if all files listed in the samplesheet.csv exist
    """
    with open(samplesheet_path, 'r') as csvfile:
        reader = csv.DictReader(csvfile)
        reader.fieldnames = [name.lstrip('#') for name in reader.fieldnames]
        
        all_exist = True
        
        for row in reader:
            file_path = Path(row['file_path'])
            if not file_path.is_file():
                print(f"ERROR: File does not exist - {file_path}")
                all_exist = False

    if not all_exist:
        print("Some files listed in the samplesheet do not exist. Please check the errors above.")
        sys.exit(1)
    else:
        print("All files exist.")

def main():
    if len(sys.argv) != 2:
        print("Usage: inputchecker.py <samplesheet.csv>")
        sys.exit(1)

    samplesheet_path = Path(sys.argv[1])  # Ensure samplesheet_path is a Path object
    
    # Check if samplesheet path is valid
    check_file_path(samplesheet_path)

    # Check if all files listed in the samplesheet exist
    check_files_exist(samplesheet_path)

if __name__ == "__main__":
    main()
