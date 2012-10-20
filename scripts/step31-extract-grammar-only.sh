#!/bin/bash
#
# Run the full pipeline, building and training the translation model against
# selected (sorted) or random (unsorted) data.

#$ -cwd
#$ -V
#$ -o log
#$ -e log
#$ -S /bin/bash
#$ -l num_proc=1,h_vmem=60g,mem_free=60g,h_rt=168:00:00
#$ -M lorland1@jhu.edu
#$ -m eas

. config.sh

#set -u
set -x
#set -e
#set -o pipefail

# Command-line arguments
joshua=$1
sorting=$2
percent_segs=$3

$joshua/scripts/training/pipeline.pl \
	--rundir runs/${percent_segs}_${sorting} \
	--source $source_lang \
	--target $target_lang \
	--no-prepare \
	--type phrasal \
	--aligner giza \
	--corpus data/selection/outdomain_${sorting}_$percent_segs.train \
	--threads 1 \
	--joshua-mem 20g \
	--buildlm-mem 20g \
	--no-mbr \
	--optimizer-runs 3 \
	--hadoop-mem 1g \
  --lm berkeleylm \
  --last-step THRAX
