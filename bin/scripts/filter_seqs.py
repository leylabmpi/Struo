#!/usr/bin/env python
from __future__ import print_function
import sys,os
import re
import argparse
import logging

desc = 'Filtering sequences based on another sequence file'
epi = """DESCRIPTION:
Filtering one fasta file to just those sequences found in another.
The sequence headers must perfectly match.

Output written to STDOUT.
"""
parser = argparse.ArgumentParser(description=desc,
                                 epilog=epi,
                                 formatter_class=argparse.RawTextHelpFormatter)
parser.add_argument('fasta_to_filter', metavar='fasta_to_filter', type=str,
                    help='Fasta to filter based on the reference')
parser.add_argument('genes_fasta_ref', metavar='fasta_ref', type=str,
                    help='Reference fasta used for filtering')
parser.add_argument('--version', action='version', version='0.0.1')

logging.basicConfig(format='%(asctime)s - %(message)s', level=logging.DEBUG)


def make_index(fasta):
    idx = {}
    with open(fasta) as inF:
        for line in inF:
            if line.startswith('>'):
                line = line.lstrip('>').rstrip()
                idx[line] = 1
    return set(idx.keys())

def filter_fasta(fasta, idx):
    with open(fasta) as inF:
        seq_name = None
        seq = ''
        for i,line in enumerate(inF):
            if line.startswith('>'):
                if i > 0:
                    if seq_name in idx:
                        print('>{}\n{}'.format(seq_name, seq), end='')
                seq_name = line.lstrip('>').rstrip()
                seq = ''
            else:
                seq += line
        if seq_name in idx:
            print('>{}\n{}'.format(seq_name, seq), end='')
                

def main(args):
    # creating an index
    seq_idx = make_index(args.genes_fasta_ref)
    # filtering the fasta
    filter_fasta(args.fasta_to_filter, seq_idx)
    
if __name__ == '__main__':
    args = parser.parse_args()
    main(args)
