#!/bin/bash
#
# Run the full pipeline, building and training the translation model against
# selected (sorted) or random (unsorted) data.

#$ -cwd
#$ -V
#$ -o log
#$ -e log
#$ -S /bin/bash
#$ -l num_proc=1,h_vmem=10g,mem_free=10g,h_rt=168:00:00
#$ -M lorland1@jhu.edu
#$ -m eas

. config.sh

set -u
set -x
set -e
set -o pipefail

# Command-line arguments
sorting=$1
pct=$2
rundir=runs/${pct}_${sorting}

$JOSHUA/scripts/training/pipeline.pl \
	--rundir $rundir \
	--source $source_lang \
	--target $target_lang \
	--no-prepare \
	--type phrasal \
	--aligner giza \
	--corpus data/selection/outdomain_${sorting}_${pct}.train \
	--threads 1 \
	--joshua-mem 4g \
	--buildlm-mem 4g \
	--no-mbr \
	--optimizer-runs 3 \
	--hadoop-mem 1g \
  --lm berkeleylm \
  --last-step THRAX \

export CACHEPIPE=$JOSHUA/scripts/training/cachepipe
export PERL5LIB+=:$CACHEPIPE
. $CACHEPIPE/bashrc

# Kick off tune-test script
data_dependencies="\
  `ls $DEV_CORPUS.$source_lang` \
  `ls $DEV_CORPUS.$target_lang` \
  `ls $TEST_CORPUS.$source_lang` \
  `ls $TEST_CORPUS.$target_lang` "
script=scripts/step32-tune-test.sh
script_cmd="$script \
  $sorting \
  $pct"
qopts="-N t${dom_abbrv}${pct}${sorting}"
cmd="qsub $qopts $script_cmd"
cachecmd tune_test_${pct}_${sorting} "$cmd" \
  $data_dependencies \
  $rundir/grammar.gz \
  $script \
  $rundir/test/final-bleu

