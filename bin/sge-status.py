#!/usr/bin/env python3
import sys
import time
import re
import subprocess
from subprocess import Popen, PIPE

# setup
jobid = sys.argv[1]
regex = re.compile(r' +')

# checking for running job with qstat
try:
    # checking qstat
    p = Popen(['qstat'], stdout=PIPE)
    output, err = p.communicate()
    for x in output.decode().split('\n'):
        y = re.split(regex, x)
        if y[0] == jobid:
            if y[4] in ['r', 'qw', 't']:
                print('running')
            elif y[4] in ['Eqw', 'd']:
                print('failed')
            else:
                print('running')
            exit(0)
    # if not listed via qstat, parsing sge accounting info
    time.sleep(1)   # in case the job hasn't been written to the account yet
    acct_file = '/var/lib/gridengine/default/common/accounting'
    cmd = 'tac {acct_file} | awk -F: -v id={jobid}'.format(acct_file=acct_file, jobid=jobid)
    cmd += " '{if ($6 == id) {print $0; exit 0}}'"
    p = Popen([cmd], stdout=PIPE, shell=True)
    output, err = p.communicate()
    for x in output.decode().split('\n'):
        y = x.split(':')
        if len(y) < 12:
            continue
        else:
            if y[12] == '0':
                print('success')
            else:
                print('failed')
            exit(0)
    print('running')
except KeyboardInterrupt:
    print("failed")


