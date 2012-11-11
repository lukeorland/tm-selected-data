#!/bin/bash
#
# Run the full pipeline, building the model with all the out-of-domain data,
# training and testing it against in-domain data.

#$ -cwd
#$ -V
#$ -o log
#$ -e log
#$ -S /bin/bash
#$ -l num_proc=8,h_vmem=100g,mem_free=100g,h_rt=168:00:00
#$ -M lorland1@jhu.edu
#$ -m eas

. config.sh

#set -u
set -x
#set -e
#set -o pipefail

# Command-line arguments
training_corpus=$1
dev_corpus=$2
test_corpus=$3
joshua=$4
rundir=$5

$joshua/scripts/training/pipeline.pl \
	--rundir  $rundir \
	--source $source_lang \
	--target $target_lang \
	--first-step TUNE \
	--grammar $rundir/grammar.gz \
	--corpus $training_corpus \
	--tune $dev_corpus \
	--test $test_corpus \
	--threads 8 \
	--joshua-mem 20g \
	--buildlm-mem 20g \
	--no-mbr \
	--optimizer-runs  3 \
	--lm berkeleylm \
	--hadoop-mem 4g

