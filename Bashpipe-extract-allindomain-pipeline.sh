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

# Extract a translation model using all the in-domain training segments.
# Train, tune, and test it.

data_dependencies=" \
			`ls $INDOMAIN_CORPUS.$source_lang` \
			`ls $INDOMAIN_CORPUS.$target_lang` \
			`ls $DEV_CORPUS.$source_lang` \
			`ls $DEV_CORPUS.$target_lang*` \
			`ls $TEST_CORPUS.$source_lang` \
			`ls $TEST_CORPUS.$target_lang*` "
script=scripts/step32-full-pipeline-all-added-data.sh
script_cmd="$script \
	$INDOMAIN_CORPUS \
	$DEV_CORPUS \
	$TEST_CORPUS \
	$JOSHUA \
	runs/all_indom_added"
cmd="qsub -N ${dom_abbrv}indom $script_cmd"
cachecmd full-pipeline-Allindomain-added "$cmd" \
	$data_dependencies \
	$script \
	runs/all_indom_added/grammar.gz \
	runs/all_indom_added/test/final-bleu
