#!/usr/bin/env python3

import sys
import zipfile
from pathlib import Path

def check_directory_path(dir_path):
    """
    Check if the provided path is a valid directory
    """
    if not Path(dir_path).is_dir():
        print(f"ERROR: {dir_path} is not a directory. Please check your provided input path.")
        sys.exit(1)

def unzip_file(zip_file, output_dir):
    """
    Unzip the specified .zip file into the output directory
    """
    sample_name = zip_file.stem
    extracted_dir = output_dir / sample_name
    extracted_dir.mkdir(exist_ok=True)

    with zipfile.ZipFile(zip_file, 'r') as zip_ref:
        zip_ref.extractall(extracted_dir)

def unzip_all_zips(dir_path, output_dir):
    """
    Unzip all .zip files in the specified directory
    """
    dir_path = Path(dir_path)  # Ensure dir_path is a Path object
    zip_files = list(dir_path.glob('*.zip'))
    output_dir.mkdir(exist_ok=True)

    # Process each .zip file
    for zip_file in zip_files:
        unzip_file(zip_file, output_dir)

    print(f"Unzipping complete. Unzipped directories are located in {output_dir}")

def main():
    if len(sys.argv) != 3:
        print("Usage: inputchecker.py <directory> <output_directory>")
        sys.exit(1)

    input_dir = Path(sys.argv[1])  # Ensure input_dir is a Path object
    output_dir = Path(sys.argv[2])  # Ensure output_dir is a Path object
    
    # Check if directory path is valid
    check_directory_path(input_dir)

    # Process files in the directory
    unzip_all_zips(input_dir, output_dir)

if __name__ == "__main__":
    main()
