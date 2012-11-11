#!/bin/bash
export CACHEPIPE=$JOSHUA/scripts/training/cachepipe
export PERL5LIB+=:$CACHEPIPE
. $CACHEPIPE/bashrc

# Read in all the configurations and set up
# directory structure
. config.sh
. setup.sh
rundir=runs/all_outdom_added

# Use a translation model extracted from all the out-domain training segments.
# Tune and test it.

data_dependencies=" \
			`ls $OUTDOMAIN_CORPUS.$source_lang` \
			`ls $OUTDOMAIN_CORPUS.$target_lang` \
			`ls $DEV_CORPUS.$source_lang` \
			`ls $DEV_CORPUS.$target_lang*` \
			`ls $TEST_CORPUS.$source_lang` \
			`ls $TEST_CORPUS.$target_lang*` "
script=scripts/step32-alltrained-tune-test.sh
script_cmd="$script \
	$OUTDOMAIN_CORPUS \
	$DEV_CORPUS \
	$TEST_CORPUS \
	$JOSHUA \
	$rundir"
cmd="qsub -N ${dom_abbrv}outdom $script_cmd"
cachecmd full-pipeline-Allindomain-added "$cmd" \
	$data_dependencies \
	$script \
	$rundir/grammar.gz \
	$rundir/test/final-bleu
