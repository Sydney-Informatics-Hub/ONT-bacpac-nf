#!/usr/bin/env python3
import argparse
import os
import re

# Define template files
TEMPLATES = {
    'report_html_template': 'bandage_template.html',
    'report_js_template': 'bandage_template.js',
    'report_css_template': 'bandage_template.css',
    'sample_template': 'bandage_sample_template.html',
    'plot_template': 'bandage_plot_template.html',
}

def main(args):
    # Read in template files
    templates = {}
    for k, f in TEMPLATES.items():
        with open(os.path.join(args.templatedir, f), 'r') as f:
            templates[k] = f.read()

    # Add <script> and <style> tags to JS and CSS templates
    templates['report_js_template'] = f'<script>{templates["report_js_template"]}</script>'
    templates['report_css_template'] = f'<style>{templates["report_css_template"]}</style>'

    # Define dictionary to hold each image's HTML section
    bandage_plots = {}

    # Process each image
    for idx, image in enumerate(args.input):
        # Read in image data
        with open(image, 'r') as f:
            image_data = f.readlines()

        # Loop through SVG lines
        # Remove XML tag
        # Update width and height values
        image_data_refined = []
        for line in image_data:
            if line.startswith('<?xml'):
                continue
            if line.startswith('<svg'):
                image_data_refined.append('<svg width="max(50%, min(500px, 100%))"')
                continue
            image_data_refined.append(line)
        image_data_refined = '\n'.join(image_data_refined)

        # Get sample name and assembler
        image_basename = os.path.basename(image)
        image_basename_split = image_basename.split('.')
        sample = image_basename_split[0:-3]
        sample = '.'.join(sample)
        sample_reg = re.sub(r'[^A-Za-z0-9_-]+', '_', sample)
        sample_reg = re.sub(r'_+$', '', sample_reg)
        assembler = image_basename_split[-3]
        id = f'{sample_reg}.{idx}'

        # Add sample to bandage_plots dict if not already present
        if sample_reg not in bandage_plots:
            bandage_plots[sample_reg] = []

        # Create report section for image
        bandage_plots[sample_reg].append(templates['plot_template'].format(
            id=id,
            assembler=assembler,
            image_data=image_data_refined
        ))

    # For each sample, join plot HTML sections together
    bandage_plots = {sample: '\n'.join(plots) for sample, plots in bandage_plots.items()}
    
    # Add plots to a sample report section
    bandage_samples = [
        templates['sample_template'].format(
            sample=sample,
            bandage_plots=plots
        )
        for sample, plots in bandage_plots.items()
    ]

    # Join sample sections into a single HTML report
    bandage_report = '\n'.join(bandage_samples)

    # Create final report from main template
    bandage_report_html = templates['report_html_template'].format(
        bandage_report=bandage_report,
        select_script=templates['report_js_template'],
        css=templates['report_css_template']
    )
    bandage_report_html = bandage_report_html + '\n'

    # Write to file
    with open('bandage_mqc.html', 'w') as f:
        f.write(bandage_report_html)


def get_args():
    parser = argparse.ArgumentParser(description="Prepare bandage SVG images for use in a MultiQC report.")
    
    # Add arguments
    parser.add_argument('--templatedir', type=str, required=True, help='Path to the template directory.')
    parser.add_argument('input', nargs='+', type=str, help='Path to the input SVG image.')
    
    # Parse arguments
    args = parser.parse_args()

    # Check inputs
    assert os.path.isdir(args.templatedir), f'Error: Template directory `{args.templatedir}` does not exist.'
    for f in TEMPLATES.values():
        assert os.path.isfile(os.path.join(args.templatedir, f)), f'Error: Required template file `{f}` does not exist in template directory.'
    for input in args.input:
        assert isinstance(input, str), 'Error: Invalid input.'
        assert input.endswith('.svg'), 'Error: Input files must be SVG images.'
        assert os.path.isfile(input), f'Error: Input file `{input}` does not exist.'

    return args


if __name__ == '__main__':
    args = get_args()
    main(args)
