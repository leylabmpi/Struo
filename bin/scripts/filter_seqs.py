#!/usr/bin/env python
from __future__ import print_function
import sys,os
import re
import gzip
import argparse
import logging

desc = 'Filtering two fasta files down to just intersection'
epi = """DESCRIPTION:
Filtering 2 fasta files down to the intersection of their sequencines.
The sequence headers must perfectly match.
If any duplicate headers, only the first will be selected.

Output written to STDOUT.
"""
parser = argparse.ArgumentParser(description=desc,
                                 epilog=epi,
                                 formatter_class=argparse.RawTextHelpFormatter)
parser.add_argument('fasta1', metavar='fasta1', type=str,
                    help='The first fasta file')
parser.add_argument('fasta2', metavar='fasta2', type=str,
                    help='The second fasta file')
parser.add_argument('fasta1_output', metavar='fasta1_output', type=str,
                    help='Name of the output fasta1 file')
parser.add_argument('fasta2_output', metavar='fasta2_output', type=str,
                    help='Name of the output fasta2 file')
parser.add_argument('--gzip', action='store_true', default=False,
                    help='gzip output')
parser.add_argument('--version', action='version', version='0.0.1')

logging.basicConfig(format='%(asctime)s - %(message)s', level=logging.DEBUG)


def make_index(fasta):
    if fasta.endswith('.gz'):
        _openR = lambda x: gzip.open(x, 'rb')
    else:
        _openR = lambda x: open(x, 'r')        
    
    idx = {}
    with _openR(fasta) as inF:
        for line in inF:
            if fasta.endswith('.gz'):
                line = line.decode('utf8')            
            if line.startswith('>'):
                line = line.lstrip('>').rstrip()
                idx[line] = 0
    return set(idx.keys())

def filter_fasta(fasta, idx, output, gzip_out=False):
    idx = {k:0 for k in idx}

    if fasta.endswith('.gz'):
        _openR = lambda x: gzip.open(x, 'rb')
    else:
        _openR = lambda x: open(x, 'r')        
    
    if gzip_out is True:
        _openW = lambda x: gzip.open(x, 'wb')
    else:
        _openW = lambda x: open(x, 'w')
    
    with _openR(fasta) as inF, _openW(output) as outF:
        seq_name = None
        seq = ''
        for i,line in enumerate(inF):
            if fasta.endswith('.gz'):
                line = line.decode('utf8')
            if line.startswith('>'):
                # previous seq
                if i > 0:
                    try:
                        if idx[seq_name] < 1:
                            x = '>{}\n{}'.format(seq_name, seq)
                            try:
                                outF.write(x)
                            except TypeError:
                                outF.write(x.encode('utf-8'))
                            idx[seq_name] += 1
                    except KeyError:
                        pass
                # next seq
                seq_name = line.lstrip('>').rstrip()
                seq = ''
            else:
                seq += line
        # final seq
        try:
            if idx[seq_name] < 1:
                x = '>{}\n{}'.format(seq_name, seq)
                try:
                    outF.write(x)
                except TypeError:
                    outF.write(x.encode('utf-8'))
                idx[seq_name] += 1
        except KeyError:
            pass

def main(args):
    # creating the seq header index
    seq_idx = make_index(args.fasta1) & make_index(args.fasta2)
    
    # filtering the fasta files
    filter_fasta(args.fasta1, seq_idx, args.fasta1_output,
                 gzip_out=args.gzip)
    filter_fasta(args.fasta2, seq_idx, args.fasta2_output,
                 gzip_out=args.gzip)
    
if __name__ == '__main__':
    args = parser.parse_args()
    main(args)
