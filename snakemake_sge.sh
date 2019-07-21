#!/bin/bash

# user input
if [ "$#" -lt 4 ]; then
    echo "snakemake_sge.sh config.yaml cluster.json SGE_log_dir jobs ..."
    echo " config.yaml : snakemake config"
    echo " cluster.json : snakemake cluster config"
    echo " SGE_log_dir : directory where all qsub job logs will be written"
    echo " jobs : number of parallel qsub jobs"
    echo " ... : additional arguments passed to snakemake"
    exit
fi

# check for snakemake
command -v snakemake >/dev/null 2>&1 || { echo "snakemake is not in your PATH"; exit 1; }

# set args
CONFIG=$1
CLUST_CONFIG=$2
SGE_LOG_DIR=$3
JOBS=$4

# max number of very large temp files
TEMPR=$JOBS
if [ $JOBS -gt 8 ]; then
    TEMPR=8
fi

# script DIR
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

# SGE output
## follow symlink
if [ ! -z `readlink -f $SGE_LOG_DIR` ]; then
    SGE_LOG_DIR=`readlink -f $SGE_LOG_DIR`
fi
## making directories if they don't exist
if [ ! -d $SGE_LOG_DIR ]; then
    mkdir -p $SGE_LOG_DIR
fi

# cluster job params (params need a starting space)
CLUSTER=$SCRIPT_DIR'/bin/sge-submit.py '$SGE_LOG_DIR

# writing jobscript.json
## needed for using conda environment
CONDAPATH=`command -v conda`
if [ ! $CONDAPATH ]; then
    echo "ERROR: conda is not in your PATH"
    exit
fi
CONDAPATH=`dirname $CONDAPATH`
CONDAPATH=`dirname $CONDAPATH`"/bin"
JOB_SCRIPT=$SGE_LOG_DIR'/jobscript.sh'
cat > $JOB_SCRIPT <<EOF
#!/bin/bash
# properties = {properties}
export PATH=$CONDAPATH:\$PATH
{exec_job}
EOF

# snakemake call
WORKDIR=`pwd`
snakemake -f \
	  --use-conda \
	  --configfile $CONFIG \
	  --cluster-config $CLUST_CONFIG \
	  --cluster "$CLUSTER" \
	  --cluster-status "$SCRIPT_DIR/bin/sge-status.py" \
	  --jobs $JOBS \
	  --local-cores $JOBS \
	  --jobscript $JOB_SCRIPT \
	  --latency-wait 120 \
	  --max-jobs-per-second 2 \
	  --max-status-checks-per-second 2 \
	  --printshellcmds \
	  --resources temp=$JOBS tempBig=$TEMPR \
	  --directory $WORKDIR \
	  "${@:5}"

#	  --restart-times 2 \

