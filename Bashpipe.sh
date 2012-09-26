#!/bin/bash

set -e
set -o pipefail

export CACHEPIPE=$JOSHUA/scripts/training/cachepipe
export PERL5LIB+=:$CACHEPIPE
. $CACHEPIPE/bashrc

# Read in all the configurations and set up
# directory structure
. config.sh
. setup.sh

# Create directory structure for derived files

# Extract the source-side vocabulary from the in-domain corpus
script=scripts/step00-extract-vocab.sh
script_cmd="$script \
	$SRILM_DIR \
	$INDOMAIN_TEXT_SOURCELANG_PROCESSED"
cmd="qrsh -cwd $script_cmd"
cachecmd extract-indomain-vocab "$cmd" \
	$INDOMAIN_TEXT_SOURCELANG_PROCESSED \
	$script \
	data/selection/indomain_sourcelang.vocab

# Build a language model from non-in-domain text, with vocabulary restricted
# by that of the in-domain corpus.
qopts="-cwd -l num_proc=1,h_vmem=8g,mem_free=8g,h_rt=24:00:00"
script=scripts/step01-build-outdomain-lm.sh
script_cmd="$script \
	$SRILM_DIR \
	$OUTDOMAIN_TEXT_SOURCELANG_PROCESSED"
cmd="qrsh $qopts $script_cmd"
cachecmd build-outdomain-lm "$cmd" \
	$INDOMAIN_TEXT_SOURCELANG_PROCESSED \
	$OUTDOMAIN_TEXT_SOURCELANG_PROCESSED \
	data/selection/indomain_sourcelang.vocab \
	data/selection/outdomain_lm.gz

# Calculate perplexities
qopts="-cwd -l num_proc=1,h_vmem=2g,mem_free=2g,h_rt=24:00:00"
script=scripts/step10-calc-ppls.sh
script_cmd="$script \
	$SRILM_DIR \
	$OUTDOMAIN_TEXT_SOURCELANG_PROCESSED \
	$INDOMAIN_LM"
cmd="qrsh $qopts $script_cmd"
cachecmd calculate-ppls "$cmd" \
	$INDOMAIN_LM \
	data/selection/outdomain_lm.gz \
	$OUTDOMAIN_TEXT_SOURCELANG_PROCESSED \
	$script \
	data/selection/ppl_indomain.txt \
	data/selection/ppl_outdomain.txt

# Subtract perplexities
qopts="-cwd -l num_proc=1,h_vmem=1g,mem_free=1g,h_rt=24:00:00"
script=scripts/step11-subtract-ppls.sh
script_cmd="$script \
	$OUTDOMAIN_TEXT_SOURCELANG_PROCESSED \
	$OUTDOMAIN_TEXT_TARGETLANG_PROCESSED"
cmd="qrsh $qopts $script_cmd"
cachecmd subtract-ppls "$cmd" \
	data/selection/ppl_indomain.txt \
	data/selection/ppl_outdomain.txt \
	$OUTDOMAIN_TEXT_SOURCELANG_PROCESSED \
	$OUTDOMAIN_TEXT_TARGETLANG_PROCESSED \
	$script \
	data/selection/ppl_diff_source_target_sorted_nodups.txt

# Extract best subsets of parallel out-of-domain training segments
for pct in $PERCENTAGES ; do
	qopts="-cwd -l num_proc=1,h_vmem=1g,mem_free=1g,h_rt=24:00:00"
	script=scripts/step20-extract-sorted-segments.sh
	script_cmd="$script \
		$pct \
		data/selection/outdomain_sorted_$pct.train.es \
		data/selection/outdomain_sorted_$pct.train.en"
	cmd="qrsh $qopts $script_cmd"
	cachecmd extract-sorted-segs-$pct-pct "$cmd" \
		data/selection/ppl_diff_source_target_sorted_nodups.txt \
		$script \
		data/selection/outdomain_sorted_$pct.train.es \
		data/selection/outdomain_sorted_$pct.train.en
done

# Extract unsorted subsets of parallel segments
for pct in $PERCENTAGES ; do
	qopts="-cwd -l num_proc=1,h_vmem=1g,mem_free=1g,h_rt=24:00:00"
	script=scripts/step21-extract-unsorted-segments.sh
	script_cmd="$script \
		$pct \
		$OUTDOMAIN_TEXT_SOURCELANG_PROCESSED \
		$OUTDOMAIN_TEXT_TARGETLANG_PROCESSED"
	cmd="qrsh $qopts $script_cmd"
	cachecmd extract-unsorted-segs-$pct-pct "$cmd" \
		$OUTDOMAIN_TEXT_SOURCELANG_PROCESSED \
		$OUTDOMAIN_TEXT_TARGETLANG_PROCESSED \
		$script \
		data/selection/outdomain_unsorted_$pct.train.es \
		data/selection/outdomain_unsorted_$pct.train.en
done

## Extract a model that has no added text from the out-of-domain corpus.
## Train, tune, and test it.
#
#data_dependencies=" \
#			`ls $EXTRA_TRAINING_CORPUS_1.$source_lang` \
#			`ls $EXTRA_TRAINING_CORPUS_1.$target_lang*` \
#			`ls $EXTRA_TRAINING_CORPUS_2.$source_lang` \
#			`ls $EXTRA_TRAINING_CORPUS_2.$target_lang*` \
#			`ls $EXTRA_TRAINING_CORPUS_3.$source_lang` \
#			`ls $EXTRA_TRAINING_CORPUS_3.$target_lang*` \
#			`ls $DEV_CORPUS.$source_lang` \
#			`ls $DEV_CORPUS.$target_lang*` \
#			`ls $TEST_CORPUS.$source_lang` \
#			`ls $TEST_CORPUS.$target_lang*` "
#script=scripts/step30-extract-grammar-no-added-data.sh
#script_cmd="$script \
#	$EXTRA_TRAINING_CORPUS_1 \
#	$EXTRA_TRAINING_CORPUS_2 \
#	$EXTRA_TRAINING_CORPUS_3 \
#	$DEV_CORPUS \
#	$TEST_CORPUS \
#	$JOSHUA"
#cmd="qsub -N pip0 $script_cmd"
#cachecmd full-pipeline-0-added "$cmd" \
#	$data_dependencies \
#	$script \
#	runs/0_added/grammar.gz

# Extract a grammar; train with selected data, tune, and test it.
# Extract a grammar; train with random data, tune, and test it.
for sorting in sorted unsorted ; do
	for pct in 15 20 ; do
		data_dependencies="\
			`ls data/selection/outdomain_${sorting}_$pct.train.*` \
			`ls $EXTRA_TRAINING_CORPUS_1.$source_lang` \
			`ls $EXTRA_TRAINING_CORPUS_1.$target_lang*` \
			`ls $EXTRA_TRAINING_CORPUS_2.$source_lang` \
			`ls $EXTRA_TRAINING_CORPUS_2.$target_lang*` \
			`ls $EXTRA_TRAINING_CORPUS_3.$source_lang` \
			`ls $EXTRA_TRAINING_CORPUS_3.$target_lang*` \
			`ls $DEV_CORPUS.$source_lang` \
			`ls $DEV_CORPUS.$target_lang*` \
			`ls $TEST_CORPUS.$source_lang*` \
			`ls $TEST_CORPUS.$target_lang*` "
		script=scripts/step31-extract-grammar-added-data.sh
		script_cmd="$script \
			$EXTRA_TRAINING_CORPUS_1 \
			$EXTRA_TRAINING_CORPUS_2 \
			$EXTRA_TRAINING_CORPUS_3 \
			$DEV_CORPUS \
			$TEST_CORPUS \
			$JOSHUA \
			$sorting \
			$pct"
		qopts="-N pip$pct${sorting}"
		cmd="qsub $qopts $script_cmd"
		cachecmd full-pipeline-${sorting}-segs-$pct-pct "$cmd" \
			$data_dependencies \
			$script \
			runs/${sorting}_$pct/grammar.gz \
			runs/${sorting}_$pct/test/1/final-bleu
	done
done
