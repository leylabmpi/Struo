# import 
from __future__ import print_function
import os
import sys
import re
import glob
import socket
import getpass
import subprocess
import pandas as pd

# setup

## load
configfile: 'config.yaml'

## outdir
config['output_dir'] = config['output_dir'].rstrip('/') + '/'

## Samples table
if not os.path.isfile(config['samples_file']):
    raise IOError('Cannot find file: {}'.format(config['samples_file']))
config['samples'] = pd.read_csv(config['samples_file'], sep='\t')
for f in [config['samples_col'], config['fasta_file_path_col'], config['taxID_col'], config['taxonomy_col']]:
    if f not in config['samples'].columns:
        raise ValueError('Cannot find column: {}'.format(f))
config['samples'][config['samples_col']] = config['samples'][config['samples_col']].str.replace('[^A-Za-z0-9]+', '_')
config['samples'] = config['samples'].set_index(config['samples'][config['samples_col']])

### check that files exist (skipping if not)
rowID = 0
to_rm = []
for index,row in config['samples'].iterrows():
    rowID += 1
    file_cols = [config['fasta_file_path_col']]
    for f in file_cols:       
    	if not os.path.isfile(str(row[f])):
           msg = 'Samples table (Row {}): Cannot find file: {}; Skipping\n'
	   sys.stderr.write(msg.format(rowID, row[f]))
	   to_rm.append(row[config['samples_col']])
sys.stderr.write('Total number of skipped rows: {}\n'.format(len(to_rm)))
config['samples'].drop(to_rm, inplace=True)
if config['samples'].shape[0] < 1:
    raise ValueError('No genomes remaining after filtering!')
config['samples_unique'] = config['samples'][config['samples_col']].unique().tolist()


## temp_folder
config['pipeline']['username'] = getpass.getuser()
config['pipeline']['email'] = config['pipeline']['username'] + '@tuebingen.mpg.de'
config['tmp_dir'] = os.path.join(config['tmp_dir'], config['pipeline']['username'])
config['tmp_dir'] = os.path.join(config['tmp_dir'], 'Struo_' + str(os.stat('.').st_ino) + '/')
print('\33[33mUsing temporary directory: {} \x1b[0m'.format(config['tmp_dir']))

## including modular snakefiles
snake_dir = config['pipeline']['snakemake_folder']
include: snake_dir + 'bin/dirs'
include: snake_dir + 'bin/Snakefile'
include: snake_dir + 'bin/kraken2/Snakefile'
include: snake_dir + 'bin/bracken/Snakefile'
include: snake_dir + 'bin/humann2/Snakefile'

## local rules
localrules: all

def all_which_input(wildcards):
    input_files = []
    # kraken2
    if not config['databases']['kraken2'].startswith('Skip'):
        if config['keep_intermediate'] == True:
            x = expand(kraken2_dir + 'added/{sample}.done',
                       sample = config['samples_unique'])
            input_files += x	    
        input_files.append(os.path.join(kraken2_dir, 'hash.k2d'))
        input_files.append(os.path.join(kraken2_dir, 'opts.k2d'))
        input_files.append(os.path.join(kraken2_dir, 'taxo.k2d'))
        input_files.append(os.path.join(kraken2_dir, 'seqid2taxid.map'))

    # bracken
    if (not config['databases']['kraken2'].startswith('Skip') and
        not config['databases']['bracken'].startswith('Skip')):
    	x = expand(os.path.join(kraken2_dir, 'database{read_len}mers.kraken'),
	           read_len = config['params']['bracken_build_read_lens'])
        input_files += x

    # humann2
    if not config['databases']['humann2_bowtie2'].startswith('Skip') and \
       not config['databases']['humann2_diamond'].startswith('Skip'):
        if config['keep_intermediate'] == True:
            if config['use_ancient'] == True:                
                x = ancient(expand(annot_dir + 'prodigal/{sample}/annot.fna.gz',
                                   sample = config['samples_unique']))
            else:			   
                x = expand(annot_dir + 'prodigal/{sample}/annot.fna.gz',
                           sample = config['samples_unique'])
            input_files += x
            if config['use_ancient'] == True:                	    
                x = ancient(expand(annot_dir + 'prodigal/{sample}/annot.faa.gz',
                                   sample = config['samples_unique']))
            else:
                x = expand(annot_dir + 'prodigal/{sample}/annot.faa.gz',
                           sample = config['samples_unique'])
            input_files += x
    if not config['databases']['humann2_bowtie2'].startswith('Skip'):
        input_files.append(os.path.join(humann2_dir, 'bowtie2_build.done'))
    if not config['databases']['humann2_diamond'].startswith('Skip'):	
        input_files.append(os.path.join(humann2_dir,'all_genes_annot.dmnd'))
    
    # ret
    return input_files

rule all:
    input:
        all_which_input

