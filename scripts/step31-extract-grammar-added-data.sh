#!/bin/bash
#
# Run the full pipeline, building and training the translation model against
# selected (sorted) or random (unsorted) data.

#$ -cwd
#$ -V
#$ -o log
#$ -e log
#$ -S /bin/bash
#$ -l num_proc=1,h_vmem=60g,mem_free=60g,h_rt=48:00:00
#$ -M lorland1@jhu.edu
#$ -m eas

. config.sh

#set -u
set -x
#set -e
#set -o pipefail

# Command-line arguments
dev_corpus=$1
test_corpus=$2
joshua=$3
sorting=$4
percent_segs=$5

$joshua/scripts/training/pipeline.pl \
	--readme "phrase-based, separate glue, twitter tokenizer" \
	--rundir runs/${sorting}_$percent_segs \
	--source $source_lang \
	--target $target_lang \
	--no-prepare \
	--type phrasal \
	--aligner giza \
	--corpus data/selection/outdomain_${sorting}_$percent_segs.train \
	--tune $dev_corpus \
	--test $test_corpus \
	--threads 1 \
	--joshua-mem 10g \
	--buildlm-mem 10g \
	--no-mbr \
	--optimizer-runs 1 \
	--hadoop-mem 500m
	#--corpus EXTRA_TRAINING_CORPUS_1 \
	#--corpus EXTRA_TRAINING_CORPUS_2 \
	#--corpus EXTRA_TRAINING_CORPUS_3 \

