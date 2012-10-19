#!/bin/bash

#set -e
#set -o pipefail

export CACHEPIPE=$JOSHUA/scripts/training/cachepipe
export PERL5LIB+=:$CACHEPIPE
. $CACHEPIPE/bashrc

# Read in all the configurations and set up
# directory structure
. config.sh
. setup.sh


# Extract a translation model using all the out-of-domain training segments.
# Train, tune, and test it.

data_dependencies=" \
			`ls $OUTDOMAIN_CORPUS.$source_lang` \
			`ls $OUTDOMAIN_CORPUS.$target_lang` \
			`ls $DEV_CORPUS.$source_lang` \
			`ls $DEV_CORPUS.$target_lang*` \
			`ls $TEST_CORPUS.$source_lang` \
			`ls $TEST_CORPUS.$target_lang*` "
script=scripts/step32-full-pipeline-all-added-data.sh
script_cmd="$script \
	$OUTDOMAIN_CORPUS \
	$DEV_CORPUS \
	$TEST_CORPUS \
	$JOSHUA"
cmd="qsub -N ${dom_abbrv}all $script_cmd"
cachecmd full-pipeline-All-added "$cmd" \
	$data_dependencies \
	$script \
	runs/all_added/grammar.gz
