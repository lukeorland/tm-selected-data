#!/bin/bash
#
# Run the full pipeline, building and training the translation model against
# selected (sorted) or random (unsorted) data.

#$ -cwd
#$ -V
#$ -o log
#$ -e log
#$ -S /bin/bash
#$ -l num_proc=8,h_vmem=70g,mem_free=70g,h_rt=168:00:00
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
	--rundir runs/${percent_segs}_${sorting} \
	--source $source_lang \
	--target $target_lang \
	--no-prepare \
	--type phrasal \
	--aligner giza \
	--corpus data/selection/outdomain_${sorting}_$percent_segs.train \
	--tune $dev_corpus \
	--test $test_corpus \
	--threads 8 \
	--joshua-mem 40g \
	--buildlm-mem 20g \
	--no-mbr \
	--optimizer-runs 1 \
	--hadoop-mem 2g \
  --lm berkeleylm
