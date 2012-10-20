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

# Just test the extracted grammars without tuning them.
for sorting in sorted unsorted ; do
	for pct in $PERCENTAGES ; do
		data_dependencies="\
			`ls $TEST_CORPUS.$source_lang*` \
			`ls $TEST_CORPUS.$target_lang*` "
		script=scripts/step33-test-only.sh
		script_cmd="$script \
			$TEST_CORPUS \
			$JOSHUA \
			$sorting \
			$pct"
		qopts="-N t${dom_abbrv}${pct}${sorting}"
		cmd="qsub $qopts $script_cmd"
		cachecmd test_${pct}_${sorting} "$cmd" \
			$data_dependencies \
			runs/${pct}_${sorting}/grammar.gz \
			$script \
			runs/${pct}_${sorting}/test/final-bleu
	done
done

