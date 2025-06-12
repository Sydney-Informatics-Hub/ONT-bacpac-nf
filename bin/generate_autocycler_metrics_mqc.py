#!/usr/bin/env python3
import pandas as pd
import argparse
import os

def main(args):
    metrics = pd.concat([
        pd.read_table(f, sep='\t', index_col='name')
        for f in args.input
    ])

    list_columns = [
        'untrimmed_cluster_size',
        'untrimmed_cluster_distance',
        'trimmed_cluster_size',
        'trimmed_cluster_median',
        'trimmed_cluster_mad',
    ]

    metrics_lists = metrics[list_columns].apply(
        lambda x: x.str.replace('[', '').str.replace(']', '').str.split(',')
    )
    metrics_lists['cluster'] = metrics_lists.apply(
        lambda x: [f'cluster_{i + 1}' for i in range(0, len(x.untrimmed_cluster_size))],
        axis=1
    )
    metrics_lists = metrics_lists.explode(list_columns + ['cluster'])
    metrics_lists['name'] = metrics_lists.index + '_' + metrics_lists['cluster']
    metrics_lists = metrics_lists.set_index('name')
    metrics_lists.drop(columns=['cluster'], inplace=True)

    non_list_columns = [c for c in metrics.columns if c not in list_columns]
    metrics = pd.concat([metrics[non_list_columns], metrics_lists]).sort_index()

    headers = '\n'.join([
        '# id: autocycler_metrics',
        '# section_name: "Autocycler Metrics"',
        '# description: "A summary of Autocycler\'s output metrics."',
        '# format: "tsv"',
        '# plot_type: "table"',
        '# pconfig:',
        '#     id: "autocycler_metrics_table"',
    ]) + '\n'

    output = headers + metrics.to_csv(sep='\t')

    with open(args.output, 'w') as f:
        f.write(output)


def get_args():
    parser = argparse.ArgumentParser(description="Prepare Autocycler metrics table for use in a MultiQC report.")
    
    # Add arguments
    parser.add_argument('-o', '--output', type=str, required=True, help='Path to the output MultiQC-ready TSV file.')
    parser.add_argument('input', type=str, nargs='+', help='Path to one or more Autocycler metrics TSV files.')
    
    # Parse arguments
    args = parser.parse_args()

    # Check inputs
    assert isinstance(args.output, str) and not os.path.exists(args.output), 'Error: Invalid output file.'
    assert isinstance(args.input, list) and all([isinstance(f, str) for f in args.input]) and all([os.path.isfile(f) for f in args.input]), 'Error: Invalid input file(s).'

    return args


if __name__ == '__main__':
    args = get_args()
    main(args)