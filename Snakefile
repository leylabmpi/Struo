# import 
from __future__ import print_function
import os
import sys
import glob
import socket
import getpass
import pandas as pd

# setup

## load
configfile: 'config.yaml'

## outdir
config['output_dir'] = config['output_dir'].rstrip('/') + '/'

## Samples table
if not os.path.isfile(config['samples_file']):
    raise IOError('Cannot find file: {}'.format(config['samples_file']))
config['samples'] = pd.read_csv(config['samples_file'], sep='\t', comment='#')
for f in [config['samples_col'], config['fasta_file_path_col'], config['taxID_col'], config['taxonomy_col']]:
    if f not in config['samples'].columns:
        raise ValueError('Cannot find column: {}'.format(f))
config['samples'][config['samples_col']] = config['samples'][config['samples_col']].str.replace('[^A-Za-z0-9]+', '_')
config['samples'] = config['samples'].set_index(config['samples'][config['samples_col']])
config['samples_unique'] = config['samples'][config['samples_col']].unique().tolist()

### check that files exist
for index,row in config['samples'].iterrows():
    file_cols = [config['fasta_file_path_col']]
    for f in file_cols:        
    	if not os.path.isfile(row[f]):
       	   raise ValueError('Cannot file file: "{}"'.format(row[f]))

## temp_folder
config['pipeline']['username'] = getpass.getuser()
config['pipeline']['email'] = config['pipeline']['username'] + '@tuebingen.mpg.de'
config['pipeline']['temp_folder'] = os.path.join(config['pipeline']['temp_folder'],
                                                 config['pipeline']['username'])
config['tmp_dir'] = os.path.join(config['pipeline']['temp_folder'],
		                 'LLMGP-DB_' + str(os.stat('.').st_ino) + '/')



## including modular snakefiles
snake_dir = config['pipeline']['snakemake_folder']
include: snake_dir + 'bin/dirs'
include: snake_dir + 'bin/kraken2/Snakefile'
include: snake_dir + 'bin/humann2/Snakefile'

## local rules
localrules: all

def all_which_input(wildcards):
    input_files = []
    if not config['params']['kraken2'].startswith('Skip'):
        input_files.append(kraken2_dir + 'hash.k2d')
    return input_files

rule all:
    input:
        # kraken
        kraken2_dir + 'hash.k2d',
        kraken2_dir + 'opts.k2d',
        kraken2_dir + 'seqid2taxid.map',
        kraken2_dir + 'taxo.k2d',
        # humann2
        humann2_dir + 'bowtie2_build.done',
        humann2_dir + 'diamond_makedb.done'


# notifications (only first & last N lines)
# onsuccess:
#     print("Workflow finished, no error")
#     cmd = "(head -n 1000 {log} && tail -n 1000 {log}) | fold -w 900 | mail -s 'LLMGP-DB finished successfully' " + config['pipeline']['email']
#     shell(cmd)

# onerror:
#     print("An error occurred")
#     cmd = "(head -n 1000 {log} && tail -n 1000 {log}) | fold -w 900 | mail -s 'LLMGP-DB => error occurred' " + config['pipeline']['email']
#     shell(cmd)
