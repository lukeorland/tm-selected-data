#!/bin/bash

export CACHEPIPE=$JOSHUA/scripts/training/cachepipe
export PERL5LIB+=:$CACHEPIPE
. $CACHEPIPE/bashrc

# Read in all the configurations
. config.sh

# Create directory structure for derived files

dirs="data \
	data/selection \
	data/test \
	data/train \
	data/tune \
	log \
	runs"
for d in $dirs ; do \
	if [ ! -d "$d" ]; then
		mkdir -p $d
	fi
done

exit

# Extract the source-side vocabulary from the in-domain corpus
script=scripts/step00-extract-vocab.sh
script_cmd="$script \
	$SRILM_DIR \
	data/train/$(basename $INDOMAIN_TEXT_SOURCELANG_PROCESSED)"
cmd="qrsh -cwd $script_cmd"
cachecmd extract-indomain-vocab "$cmd" \
	data/train/$(basename $INDOMAIN_TEXT_SOURCELANG_PROCESSED) \
	$script \
	data/selection/indomain_sourcelang.vocab

# Build a language model from non-in-domain text, with vocabulary restricted
# by that of the in-domain corpus.
qopts="-cwd -l num_proc=1,h_vmem=8g,mem_free=8g,h_rt=24:00:00"
script=scripts/step01-build-outdomain-lm.sh
script_cmd="$script \
	$SRILM_DIR \
	data/train/$(basename $OUTDOMAIN_TEXT_SOURCELANG_PROCESSED)"
cmd="qrsh $qopts $script_cmd"
cachecmd build-outdomain-lm "$cmd" \
	data/selection/indomain_sourcelang.vocab \
	data/train/$(basename $OUTDOMAIN_TEXT_SOURCELANG_PROCESSED) \
	data/selection/$(basename $INDOMAIN_TEXT_SOURCELANG_PROCESSED) \
	data/selection/outdomain_lm.gz

# Calculate perplexities
qopts="-cwd -l num_proc=1,h_vmem=2g,mem_free=2g,h_rt=24:00:00"
script=scripts/step10-calc-ppls.sh
script_cmd="$script \
	$SRILM_DIR \
	data/train/$(basename $OUTDOMAIN_TEXT_SOURCELANG_PROCESSED) \
	data/selection/indomain_lm.gz"
cmd="qrsh $qopts $script_cmd"
cachecmd calculate-ppls "$cmd" \
	data/selection/indomain_lm.gz \
	data/selection/outdomain_lm.gz \
	$OUTDOMAIN_TEXT_SOURCELANG_PROCESSED \
	$script \
	data/selection/ppl_indomain.txt \
	data/selection/ppl_outdomain.txt

# Subtract perplexities
qopts="-cwd -l num_proc=1,h_vmem=1g,mem_free=1g,h_rt=24:00:00"
script=scripts/step11-subtract-ppls.sh
script_cmd="$script \
	data/train/$(basename $OUTDOMAIN_TEXT_SOURCELANG_PROCESSED) \
	data/train/$(basename $OUTDOMAIN_TEXT_TARGETLANG_PROCESSED)"
cmd="qrsh $qopts $script_cmd"
cachecmd subtract-ppls "$cmd" \
	data/selection/ppl_indomain.txt \
	data/selection/ppl_outdomain.txt
	data/train/$(basename $OUTDOMAIN_TEXT_SOURCELANG_PROCESSED) \
	data/train/$(basename $OUTDOMAIN_TEXT_TARGETLANG_PROCESSED) \
	$script \
	data/selection/ppl_diff_source_target_sorted_nodups.txt

# Extract best subsets of parallel out-of-domain training segments

for pct in $PERCENTAGES ; do
	qopts="-cwd -l num_proc=1,h_vmem=1g,mem_free=1g,h_rt=24:00:00"
	script=scripts/step20-extract-sorted-segments.sh
	script_cmd="$script $pct"
	cmd="qrsh $qopts $script_cmd"
	cachecmd extract-sorted-segs-$pct-pct "$cmd" \
		data/selection/ppl_diff_source_target_sorted_nodups.txt
		$script \
		data/train/outdomain_sorted_$pct.train.es \
		data/train/outdomain_sorted_$pct.train.en
done

# Extract unsorted subsets of parallel segments

for pct in $PERCENTAGES ; do
	qopts="-cwd -l num_proc=1,h_vmem=1g,mem_free=1g,h_rt=24:00:00"
	script=scripts/step21-extract-unsorted-segments.sh
	script_cmd="$script \
		$pct \
		data/train/$(basename $OUTDOMAIN_TEXT_SOURCELANG_PROCESSED) \
		data/train/$(basename $OUTDOMAIN_TEXT_TARGETLANG_PROCESSED)"
	cmd="qrsh $qopts $script_cmd"
	cachecmd extract-unsorted-segs-$pct-pct "$cmd" \
		data/train/$(basename $OUTDOMAIN_TEXT_SOURCELANG_PROCESSED) \
		data/train/$(basename $OUTDOMAIN_TEXT_TARGETLANG_PROCESSED) \
		$script \
		data/train/outdomain_unsorted_$pct.train.es \
		data/train/outdomain_unsorted_$pct.train.en
done

# Extract a model that has no added text from the out-of-domain corpus.
# Train, tune, and test it.

data_dependencies="`ls data/train/$(basename $EXTRA_TRAINING_CORPUS_1).*` \
	`ls data/train/$(basename $EXTRA_TRAINING_CORPUS_2).*` \
	`ls data/train/$(basename $EXTRA_TRAINING_CORPUS_3).*` \
	`ls data/tune/$(basename $DEV_CORPUS).*` \
	`ls data/test/$(basename $TEST_CORPUS).*` "
qopts="-cwd -e log -o log -N full-pipeline-0-added"
script=scripts/step30-extract-grammar-no-added-data.sh
script_cmd="$script \
	data/train/$(basename $EXTRA_TRAINING_CORPUS_1) \
	data/train/$(basename $EXTRA_TRAINING_CORPUS_2) \
	data/train/$(basename $EXTRA_TRAINING_CORPUS_3) \
	data/tune/$(basename $DEV_CORPUS) \
	data/test/$(basename $TEST_CORPUS) \
	$JOSHUA"
cmd="qsub -cwd $qopts $script_cmd"
cachecmd full-pipeline-0-added "$cmd" \
	$data_dependencies \
	$script \
	runs/0_added/grammar.gz

# Extract a grammar; train with selected data, tune, and test it.
# Extract a grammar; train with random data, tune, and test it.
for sorting in sorted unsorted ; do
	for pct in $PERCENTAGES ; do
		data_dependencies="`ls data/train/outdomain_${sorting}_$pct.train.*` \
			`ls data/train/$(basename $EXTRA_TRAINING_CORPUS_1).*` \
			`ls data/train/$(basename $EXTRA_TRAINING_CORPUS_2).*` \
			`ls data/train/$(basename $EXTRA_TRAINING_CORPUS_3).*` \
			`ls data/tune/$(basename $DEV_CORPUS).*` \
			`ls data/test/$(basename $TEST_CORPUS).*` "
		qopts="-cwd -e log -o log -N full-pipeline-${sorting}-$pct"
		script=scripts/step31-extract-grammar-added-data.sh
		script_cmd="$script \
			data/train/$(basename $EXTRA_TRAINING_CORPUS_1) \
			data/train/$(basename $EXTRA_TRAINING_CORPUS_2) \
			data/train/$(basename $EXTRA_TRAINING_CORPUS_3) \
			data/tune/$(basename $DEV_CORPUS) \
			data/test/$(basename $TEST_CORPUS) \
			$JOSHUA \
			$sorting \
			$pct"
		cmd="qsub -cwd $qopts $script_cmd"
		cachecmd full-pipeline-${sorting}-segs-$pct-pct "$cmd" \
			$data_dependencies \
			$script \
			runs/${sorting}_$pct/grammar.gz \
			runs/${sorting}_$pct/test/1/final-bleu

	done
done
