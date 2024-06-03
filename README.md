# ONT-bacpac-nf

WIP title, WIP workflow. 

## Workflow description 

A rapid and portable workflow for pond-side sequencing of bacterial pathogens for sustainable aquaculture using ONT long-read sequencing. 

## User guide 

Functionality implemented: 

1. Input directory checker and upzip .zips
2. Concat .fq.gz files per sample 
3. TODO Run pycoQC on total run 
4. TODO Run porechop on raw sequence QC (barcode-level)
5. 

Dev execution: 

```bash 
module load singularity 
module load nextflow/24.04.1
```

```bash
nextflow run main.nf --input <path_to_dir>
```

## Component tools 

## Additional notes

## Help / FAQ / Troubleshooting

## License(s)

## Acknowledgements/citations/credits
