# Getting started

The bacpac pipeline is designed as a rapid and portable workflow to process ONT long-read sequencing data for the purpose of pond-side detection of bacterial pathogens for sustainable aquaculture.

The pipeline is designed using Nextflow and utilises common, well-tested tools for bacterial genome and plasmid assembly, quality control, DNA contamination detection, and antibiotic resistance gene annotation.

## Software requirements

At a minimum, you will require the following installed on your system:

- Java version 17 or later
- Nextflow version 24 or later
    - See the [Nextflow docs](https://www.nextflow.io/docs/latest/install.html) for information on installing both Nextflow and Java
- Singularity

The workflow has been designed to primarily run on NCI's [gadi](https://nci.org.au/our-systems/hpc-systems) high performance computing infrastructure.

## Cloning the workflow

To pull the pipeline to your local working directory, simply run:

```bash
git clone https://github.com/Sydney-Informatics-Hub/ONT-bacpac-nf.git
```

This workflow is still being actively maintained and developed, so updates are being made regularly. To run a newer version of the pipeline, we recommend creating a new working directory and pulling the workflow again with `git clone` rather than updating an existing working directory, to ensure you don't run into any potential version conflicts or incompatibilities between versions.

## Pre-downloading the Kraken2 database

We recommend pre-downloading a Kraken2 database as it can be quite slow to download as part of the pipeline. You can find links to these databases [here](https://benlangmead.github.io/aws-indexes/k2). We have tested this pipeline with the [Standard Kraken2 database from 12 January 2024](https://genome-idx.s3.amazonaws.com/kraken/k2_standard_20240112.tar.gz).

## Sequencing summary

ONT sequencing runs will generate a sequencing summary text file, named something like `sequencing_summary_*.txt`. This file is used by multiple quality control steps of the pipeline. The way you supply it to the pipeline depends on whether you run the workflow using an input directory or a samplesheet (see the [next section](#running-the-workflow)).

## Running the workflow

The pipeline takes either a sequencing data directory or a CSV samplesheet as its input.

### Input directory method (single batch, one sample per library/barcode)

If you are working with a single batch of data from one flow cell, and if every library/barcode is associated with a single sample, then you can use the sequencing data directory method. A sequencing data directory should contain FASTQs for one or more samples, with each sample's FASTQs either organised into a separate subdirectory or compressed as a `.zip` file. Each sample may have multiple FASTQ files associated with it. For example, in the following example, the sequencing directory `/example/sequencing/directory` contains the data for `barcode01` and `barocde02` within subdirectories, and `barcode03` and `barcode04` as `.zip` files:

```bash
tree /example/sequencing/directory
```

```console
/example/sequencing/directory
├── barcode01
│   ├── FAX12345_pass_barcode01_6789abcd_ef012345_0.fastq.gz
│   └── FAX12345_pass_barcode01_6789abcd_ef012345_1.fastq.gz
├── barcode02
│   ├── FAX23456_pass_barcode01_789abcde_f0123456_0.fastq.gz
│   └── FAX23456_pass_barcode01_789abcde_f0123456_1.fastq.gz
├── barcode03.zip
└── barcode04.zip
```

You can specify to process all the samples within a directory with the `--input_directory` parameter, and simultaneously pass the sequencing summary file with the `--sequencing_summary` parameter:

```bash
nextflow run main.nf --input_directory /path/to/dataset --sequencing_summary /path/to/sequencing_summary.txt [...]
```

### Samplesheet method (preferred)

If you wish to run multiple batches (i.e. multiple flow cells) of data through the pipeline in one run, or have multiple libraries/barcodes associated with a single sample (possibly spread across multiple batches), then you will need to use a samplesheet to provide the input information to the pipeline.

A samplesheet is a `.csv` file that should be formatted as follows:

```csv
barcode,sample,batch,file_path,sequencing_summary
barcode01,sample01,batch1,/path/to/dataset/barcode01,/path/to/dataset/sequencing_summary_batch1.txt
barcode02,sample02,batch1,/path/to/dataset/barcode02,/path/to/dataset/sequencing_summary_batch1.txt
barcode03,sample03,batch2,/path/to/dataset/barcode03.zip,/path/to/dataset/sequencing_summary_batch2.txt
barcode04,sample03,batch2,/path/to/dataset/barcode04.zip,/path/to/dataset/sequencing_summary_batch2.txt
```

In this case, the path to the directory or `.zip` file containing a sample's FASTQs is provided under the `file_path` column and the path to each batch's sequencing summary file is provided under the `sequencing_summary` column.

If you only have a single batch of data, you can omit the `batch` column and your data will be given the default batch ID of `batch0`.

If each sample is only associated with a single library/barcode, you can also omit the `sample` column, and the `barcode` value will be used as the `sample` value.

If you have multiple barcodes associated with a sample (for example, `barcode03` and `barcode04` in the above example), the FASTQs for these libraries will be concatenated together into a single FASTQ for genome assembly and analysis. You should only combine libraries like this if you are sure they are of similar quality, as poor quality libraries will be detrimental to genome assembly and downstream analysis.

To use a samplesheet, you can use the `--samplesheet` parameter:

```bash
nextflow run main.nf --samplesheet /path/to/samplesheet.csv [...]
```

### Databases

If supplying a pre-downloaded Kraken2 database, use the `--kraken2_db` parameter to provide the directory containing the database files (i.e. `hash.k2d`, `ktaxonomy.tsv`, `opts.k2d`, and `taxo.k2d`):

```bash
nextflow run main.nf --kraken2_db /path/to/kraken2/db [...]
```

### Execution on gadi

If running on NCI's gadi, you will also need to provide the following paramters:

- `--gadi_storage <STORAGE_STRING>`
    - `STORAGE_STRING` should be a `+`-delimited list of NCI storage systems that you will require, e.g. `scratch/ab01` or `scratch/ab01+gdata/ab01`
- `--gadi_account <PROJ>`
    - `PROJ` should be your NCI project ID, e.g. `ab01`
    - Only required if you wish to use a different account than your default NCI account.

You will also need to specify to use the `gadi` Nextflow profile, e.g.:

```bash
nextflow run main.nf -profile gadi [...]
```
For detailed instructions on scaling up the pipeline on Gadi, see [docs/gadi-execution.md](docs/gadi-execution.md).

### Accuracy mode

The pipeline expects by default that your samples have been called with fast basecalling - a quick but low-accuracy mode provided by Nanopore. If you have run basecalling with higher accuracy, you should also enable the `high_accuracy` profile to ensure the genome assembly steps have enough resources to complete successfully:

```bash
nextflow run main.nf -profile gadi,high_accuracy [...]
```

#### Subsampling

Autocycler supports subsampling your reads prior to assembly and consensus generation. This can improve the clustering step and improve the accuracy of your consensus sequence. By default, the pipeline is set to use 4 subsamples. You can change this value with the `--subsamples` parameter:

```bash
nextflow run main.nf --subsamples 8 [...]
```

#### Consensus assembly failures

In some cases, such as samples with low coverage or high fragmentation, the consensus assembly method may fail. In these cases, the pipeline will fall back to using one of the de novo assembly methods (currently either Unicycler or Flye). If this occurs, a message will be printed to the terminal and/or standard output where the pipeline is running, and a table of failed samples will appear at the top of the MultiQC reports.

When generating a consensus sequence with autocycler, one of the causes of such a failure is if the mean number of contigs per assembly exceeds a set value. This threshold is `25` by default, but can be changed by providing the `--max_contigs` parameter when running Nextflow:

```bash
nextflow run main --max_contigs 50 [...]
```

Note that this may fix the issue in some cases, but for highly fragmented assemblies, autocycler may still fail to generate a consensus sequence.

### Putting it together

A typical run might look like the following. Assuming a run on gadi, with a pre-downloaded Kraken2 database at `/scratch/ab01/kraken_db`, a samplesheet at `/scratch/ab01/samplesheet.csv`, and high-accuracy basecalling, we would do the following:

```bash
module load nextflow/24.04.1
module load singularity

nextflow run main.nf \
    --samplesheet /scratch/ab01/samplesheet.csv \
    --kraken2_db /scratch/ab01/kraken_db \
    --gadi_account ab01 \
    --gadi_storage scratch/ab01 \
    -profile gadi,high_accuracy \
    -resume
```

## Outputs

By default, the pipeline will output all results to the `results/` directory. This can be changed by supplying the `--outdir` parameter, e.g.:

```bash
nextflow run main.nf --outdir 2025-06-01_results [...]
```

The output directory will contain the following sub-directories:

- `assemblies`: Your completed genome assemblies.
- `quality_control`: Quality information assessed by QUAST, BUSCO, Kraken2, PycoQC, and NanoPlot.
- `annotations`: Annotations for antimicrobial resistance genes, virulence genes, plasmid annotations, and bacterial genome annotations.
- `taxonomy`: Phylogenetic tree information.
- `report`: MultiQC reports summarising the pipeline run.

For detailed information about interpreting the pipeline results, see [docs/interpreting-results.md](docs/interpreting-results.md)

## Next steps

This pipeline has been primarily developed for use on NCI's gadi. For more information about running the pipeline at scale on that system, see [docs/gadi-execution.md](docs/gadi-execution.md).

## Feedback and updates

Bugs, as well as suggested enhancements and new features can be reported and tracked in the [issues](https://github.com/Sydney-Informatics-Hub/ONT-bacpac-nf/issues) section of the GitHub repository.

Please add any features or issues you would like to see addressed to the issues section.
