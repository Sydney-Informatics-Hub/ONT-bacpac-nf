#!/usr/bin/env python3
  
#########################################################
#
# Platform: NCI Gadi HPC
#
# Author: Nandan Deshpande
# nandan.deshpande@sydney.edu.au
#
# If you use this script towards a publication, please acknowledge the
# Sydney Informatics Hub (or co-authorship, where appropriate).
#
# Suggested acknowledgement:
# The authors acknowledge the scientific and technical assistance
# <or e.g. bioinformatics assistance of <PERSON>> of Sydney Informatics
# Hub and resources and services from the National Computational
# Infrastructure (NCI), which is supported by the Australian Government
# with access facilitated by the University of Sydney.
#
#########################################################

# Description: A script which parses out required graphs from the pycoqc_output.html 

import os
import sys


def read_header(pycoqc_header_file_path):
    """
    Read the static header text in a variable
    """
    file_header=open("%s"%pycoqc_header_file_path)
    data_header=file_header.read()
    file_header.close()

    return data_header


def extract_html_text(each_graph,data_pycoqc_full):
 
    split_string='<div id="'+each_graph
    sp_start=data_pycoqc_full.split(split_string)
    required_segment=sp_start[1].split('</script>')[0]+'</script>\n</div>'

    out_string='<div id="'+each_graph+required_segment

    return out_string


def main():

    complete_pycoqc_output_path=sys.argv[1]
    pycoqc_header_file_path=sys.argv[2] 

    # Read pycoqc output
    file_pycoqc_full=open("%s"%complete_pycoqc_output_path)
    data_pycoqc_full=file_pycoqc_full.read()
    file_pycoqc_full.close()


    # Read header text
    data_header=read_header(pycoqc_header_file_path)

    required_graphs=["Basecalled reads length","Basecalled reads PHRED quality","Number of reads per barcode"]

    # Write the selected graph html text to output string
    out_string_final=data_header

    # Iterate over each required graph-type
    for each_graph in required_graphs:
        out_string=extract_html_text(each_graph,data_pycoqc_full)
        out_string_final=out_string_final+"\n"+out_string
        
    out_string_final=out_string_final+"</body>\n</html>"

    out_file_name="pycoQC_mqc.html"
    file_out=open("%s"%out_file_name,"w")
    file_out.write("%s"%out_string_final)
    file_out.close()

    # move phylogeny folder out of results
    #mv_string="mv phylogeny ./"
    #os.system(mv_string)

    return


main()
