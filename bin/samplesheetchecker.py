#!/usr/bin/env python3

import csv
import sys
import gzip
from pathlib import Path

def check_file_exists(file_path):
    return Path(file_path).is_file()

def validate_samplesheet(samplesheet_path):
    # Check if the samplesheet path is correct
    if not Path(samplesheet_path).is_file():
        print("Error: Invalid path to samplesheet.")
        sys.exit(1)

    # Open the samplesheet csv
    with open(samplesheet_path, 'r') as file:
        reader = csv.reader(file)
        headers = next(reader)  # Read the header

        # Check if the header matches the expected format
        expected_header = ['sample', 'fq1', 'fq2', 'platform', 'library', 'center']
        if headers != expected_header:
            print("Error: Invalid header format.")
            sys.exit(1)

        # Check columns for all rows are csv
        for row in reader:
            for column in row:
                if '\t' in column:
                    print("Error: Found a column with a tab delimiter, expected csv.")
                    sys.exit(1)

def main():
    input_csv = sys.argv[1]

    # Validate samplesheet
    validate_samplesheet(input_csv)

if __name__ == "__main__":
    main()