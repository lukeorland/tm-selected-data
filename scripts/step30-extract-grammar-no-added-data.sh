#!/bin/bash
#
# Run the full pipeline, building and training the translation model against
# fixed data with no added non-in-domain data.

#$ -cwd
#$ -V
#$ -o log
#$ -e log
#$ -S /bin/bash
#$ -l num_proc=1,h_vmem=20g,mem_free=20g,h_rt=168:00:00
#$ -M lorland1@jhu.edu
#$ -m eas

#set -u
set -x
#set -e
#set -o pipefail

# Command-line arguments
extra_training_corpus_1=$1
extra_training_corpus_2=$2
extra_training_corpus_3=$3
dev_corpus=$4
test_corpus=$5
joshua=$6

$joshua/scripts/training/pipeline.pl \
	--readme "phrase-based, separate glue, twitter tokenizer" \
	--rundir runs/0_added \
	--source es \
	--target en \
	--no-prepare \
	--type phrasal \
	--aligner giza \
	--corpus $extra_training_corpus_1 \
	--tune $dev_corpus \
	--test $test_corpus \
	--threads 8 \
	--joshua-mem 4g \
	--buildlm-mem 4g \
	--no-mbr \
	--optimizer-runs 1 \
	--hadoop-mem 500m
