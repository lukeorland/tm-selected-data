#!/bin/bash
#
# Run the full pipeline, building the model with all the out-of-domain data,
# training and testing it against in-domain data.

#$ -cwd
#$ -V
#$ -o log
#$ -e log
#$ -S /bin/bash
#$ -l num_proc=8,h_vmem=45g,mem_free=45g,h_rt=168:00:00
#$ -M lorland1@jhu.edu
#$ -m eas

. config.sh

#set -u
set -x
#set -e
#set -o pipefail

# Command-line arguments
sorting=$1
pct=$2
rundir=runs/${pct}_${sorting}

$JOSHUA/scripts/training/pipeline.pl \
	--first-step TUNE \
	--grammar $rundir/grammar.gz \
	--corpus data/selection/outdomain_${sorting}_${pct}.train \
	--lm berkeleylm \
	--rundir $rundir \
	--source $source_lang \
	--target $target_lang \
	--no-prepare \
	--type phrasal \
	--tune $DEV_CORPUS \
	--test $TEST_CORPUS \
	--threads 8 \
	--joshua-mem 15g \
	--buildlm-mem 15g \
	--no-mbr \
	--optimizer-runs  3 \

