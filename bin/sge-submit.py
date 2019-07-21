#!/usr/bin/env python3
import os
import sys
import re
import subprocess

from snakemake.utils import read_job_properties

# load
## loading job stdout & stderr path
log_path = sys.argv[-2]
## loading job script (provided by snakemake)
job_script = sys.argv[-1]
job_properties = read_job_properties(job_script)

# getting job parameters from snakemake-generated job script 
try:
    threads = job_properties['threads']
except KeyError:
    threads = 1
try:
    time = job_properties['cluster']['time']
except KeyError:
    time = '00:59:00'
try:
    n = job_properties['cluster']['n']
except KeyError:
    n = 1
try:
    mem = job_properties['cluster']['mem']
except KeyError:
    mem = 10
try:
    tmpfs = '-l tmpfs={}G'.format(job_properties['cluster']['tmpfs'])
except KeyError:
    tmpfs = ""
try:
    std_out = os.path.join(log_path, job_properties['cluster']['output'])
except KeyError:
    std_out = os.path.join(log_path, '{cluster.output}')
try:
    std_err = os.path.join(log_path, job_properties['cluster']['error'])
except KeyError:
    std_err = os.path.join(log_path, '{cluster.error}')

# removing 'special' characters in log paths (default for snakemake)
std_out = std_out.replace(',', '.').replace('=', '-')
std_err = std_err.replace(',', '.').replace('=', '-')
    
# formatting time if provided (assuming minutes)
if re.match('^[0-9]+$', time):
    hours = int(int(time) / 60)
    minutes = int(time) % 60 
    time = '{:0>2}:{:0>2}:00'.format(hours, minutes)

# formatting qsub command
cmd = "qsub -pe parallel {n} -l h_vmem={mem}G -l h_rt={time} {tmpfs} -o {std_out} -e {std_err} {job_script}"
cmd = cmd.format(n=n, mem=mem, time=time, tmpfs=tmpfs,
                 std_out=std_out, std_err=std_err, job_script=job_script)

# subprocess job: qsub
try:
    res = subprocess.run(cmd, check=True, shell=True, stdout=subprocess.PIPE)
except subprocess.CalledProcessError as e:
    raise e

# get qsub job ID
res = res.stdout.decode()
try:
    m = re.search("Your job (\d+)", res)
    jobid = m.group(1)
    print(jobid)
except Exception as e:
    print(e)
    raise
