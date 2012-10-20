#!/bin/bash
#
# Run the full pipeline, building and training the translation model against
# selected (sorted) or random (unsorted) data.

#$ -cwd
#$ -V
#$ -o log
#$ -e log
#$ -S /bin/bash
#$ -l num_proc=8,h_vmem=60g,mem_free=60g,h_rt=168:00:00
#$ -M lorland1@jhu.edu
#$ -m eas

. config.sh

#set -u
set -x
#set -e
#set -o pipefail

# Command-line arguments
test_corpus=$1
joshua=$2
sorting=$3
percent_segs=$4
rundir=runs/${percent_segs}_${sorting}

$joshua/scripts/training/pipeline.pl \
	--rundir $rundir \
	--source $source_lang \
	--target $target_lang \
	--test $test_corpus \
	--no-filter-tm
	--grammar $rundir/grammar.gz \
	--threads 8 \
	--joshua-mem 20g \
	--buildlm-mem 20g \
	--no-mbr \
  --lmfile $rundir/lm.gz \
  --first-step TEST

