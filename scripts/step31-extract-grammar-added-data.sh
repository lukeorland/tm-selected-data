#!/bin/bash
#
# Run the full pipeline, building and training the translation model against
# selected (sorted) or random (unsorted) data.

#$ -cwd
#$ -S /bin/bash
#$ -l num_proc=1,h_vmem=30,mem_free=30g,h_rt=48:00:00
#$ -M lorland1@jhu.edu
#$ -m eas

set -u
set -x
set -e
set -o pipefail

# Command-line arguments
extra_training_corpus_1=$1
extra_training_corpus_2=$2
extra_training_corpus_3=$3
dev_corpus=$4
test_corpus=$5
joshua=$6
sorting=$7
percent_segs=$8

$joshua/scripts/training/pipeline.pl \
	--readme "phrase-based, separate glue, twitter tokenizer" \
	--rundir runs/${sorting}_$percent_segs \
	--source es \
	--target en \
	--no-prepare \
	--type phrasal \
	--aligner berkeley \
	--corpus data/train/outdomain_${sorting}_$percent_segs.train \
	--corpus $extra_training_corpus_1 \
	--corpus $extra_training_corpus_2 \
	--corpus $extra_training_corpus_3 \
	--tune $dev_corpus \
	--test $test_corpus \
	--threads 8 \
	--joshua-mem 10g \
	--buildlm-mem 10g \
	--no-mbr \
	--optimizer-runs 1
