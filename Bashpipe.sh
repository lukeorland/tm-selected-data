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

# Use the same number of segment in the non-domain-specific and in-domain sets
# for the perplexity calculations.
outdomain_source_text_lm_subset=data/selection/outdomain_segs.$source_lang
outdomain_target_text_lm_subset=data/selection/outdomain_segs.$target_lang

cmd_script=scripts/step00-trim-outdomain-text.sh
cachecmd trim-outdomain-text "$cmd_script" \
  $INDOMAIN_TEXT_SOURCELANG_PROCESSED \
  $OUTDOMAIN_TEXT_SOURCELANG_PROCESSED \
  $OUTDOMAIN_TEXT_TARGETLANG_PROCESSED \
  $cmd_script \
  $outdomain_source_text_lm_subset \
  $outdomain_target_text_lm_subset

# Extract the source-side vocabulary from the in-domain corpus
script=scripts/step00-extract-source-vocab.sh
script_cmd="$script \
	$SRILM_DIR \
	$INDOMAIN_TEXT_SOURCELANG_PROCESSED"
qopts="-cwd -V -e log -o log -l num_proc=1,h_vmem=8g,mem_free=8g,h_rt=24:00:00"
cmd="qrsh $qopts $script_cmd"
cachecmd extract-indomain-source-vocab "$cmd" \
	$INDOMAIN_TEXT_SOURCELANG_PROCESSED \
	$script \
	data/selection/indomain_sourcelang.vocab

# Build a language model from the subset of non-domain-specific source-side
# text, with vocabulary restricted by that of the in-domain corpus.
script=scripts/step01-build-outdomain-lm.sh
script_cmd="$script \
	$SRILM_DIR \
	$outdomain_source_text_lm_subset \
	data/selection/indomain_sourcelang.vocab \
	data/selection/outdomain_source_lm.gz"
qopts="-cwd -V -e log -o log -l num_proc=1,h_vmem=8g,mem_free=8g,h_rt=24:00:00"
cmd="qrsh $qopts $script_cmd"
cachecmd build-source-outdomain-lm "$cmd" \
	$outdomain_source_text_lm_subset \
	data/selection/indomain_sourcelang.vocab \
  $script \
	data/selection/outdomain_source_lm.gz

# Build a language model from in-domain source-side text.
script=scripts/step02-build-indomain-lm.sh
script_cmd="$script \
	$SRILM_DIR \
	$INDOMAIN_TEXT_SOURCELANG_PROCESSED \
  data/selection/indomain_source_lm.gz"
qopts="-cwd -V -e log -o log -l num_proc=1,h_vmem=8g,mem_free=8g,h_rt=24:00:00"
cmd="qrsh $qopts $script_cmd"
cachecmd build-source-indomain-lm "$cmd" \
	$INDOMAIN_TEXT_SOURCELANG_PROCESSED \
  $script \
	data/selection/indomain_source_lm.gz

# Calculate perplexities on source side
script=scripts/step10-calc-ppls.sh
script_cmd="$script \
	$SRILM_DIR \
	$OUTDOMAIN_TEXT_SOURCELANG_PROCESSED \
	data/selection/outdomain_source_lm.gz \
	data/selection/indomain_source_lm.gz \
	data/selection/ppl_source_outdomain.txt \
	data/selection/ppl_source_indomain.txt"
qopts="-cwd -V -e log -o log -l num_proc=1,h_vmem=2g,mem_free=2g,h_rt=24:00:00"
cmd="qrsh $qopts $script_cmd"
cachecmd calculate-source-ppls "$cmd" \
	$OUTDOMAIN_TEXT_SOURCELANG_PROCESSED \
	data/selection/outdomain_source_lm.gz \
	data/selection/indomain_source_lm.gz \
	$script \
	data/selection/ppl_source_indomain.txt \
	data/selection/ppl_source_outdomain.txt

# Subtract source perplexities
script=scripts/step11-subtract-ppls.sh
script_cmd="$script \
	data/selection/ppl_source_indomain.txt \
	data/selection/ppl_source_outdomain.txt \
	data/selection/ppl_source_diff.txt"
qopts="-cwd -V -e log -o log -l num_proc=1,h_vmem=2g,mem_free=2g,h_rt=24:00:00"
cmd="qrsh $qopts $script_cmd"
cachecmd subtract-source-ppls "$cmd" \
	data/selection/ppl_source_indomain.txt \
	data/selection/ppl_source_outdomain.txt \
	$script \
	data/selection/ppl_source_diff.txt

# Paste source and target after the ppl diffs
script=scripts/step12-paste-source-target.sh
script_cmd="$script \
  $OUTDOMAIN_TEXT_SOURCELANG_PROCESSED \
  $OUTDOMAIN_TEXT_TARGETLANG_PROCESSED"
qopts="-cwd -V -e log -o log -l num_proc=1,h_vmem=2g,mem_free=2g,h_rt=24:00:00"
cmd="qrsh $qopts $script_cmd"
cachecmd paste-ppl-diffs-source-target "$cmd" \
	data/selection/ppl_source_diff.txt \
	$script \
	data/selection/ppl_diffs.txt

# Sort and remove duplicates
script=scripts/step13-sort-no-dups.sh
script_cmd="$script"
qopts="-cwd -V -e log -o log -l num_proc=1,h_vmem=2g,mem_free=2g,h_rt=24:00:00"
cmd="qrsh $qopts $script_cmd"
cachecmd sort-dedup "$cmd" \
	data/selection/ppl_diffs.txt \
	$script \
	data/selection/ppl_diffs_sorted_nodups.txt

# Extract best subsets of parallel out-of-domain training segments
for pct in $PERCENTAGES ; do
	script=scripts/step20-extract-sorted-segments.sh
	script_cmd="$script \
		$pct \
		data/selection/outdomain_sorted_$pct.train.$source_lang \
		data/selection/outdomain_sorted_$pct.train.$target_lang"
  qopts="-cwd -V -e log -o log -l num_proc=1,h_vmem=1g,mem_free=1g,h_rt=24:00:00"
	cmd="qrsh $qopts $script_cmd"
	cachecmd extract-sorted-segs-$pct-pct "$cmd" \
	  data/selection/ppl_diffs_sorted_nodups.txt \
		$script \
		data/selection/outdomain_sorted_$pct.train.$source_lang \
		data/selection/outdomain_sorted_$pct.train.$target_lang
done

# Extract a grammar from selected data; Don't tune it or test it.
# The finished extraction script kicks off a tune-test script.
sorting=sorted
for pct in $PERCENTAGES ; do
  rundir=runs/${pct}_${sorting}
  data_dependencies="\
    `ls data/selection/outdomain_${sorting}_${pct}.train.*` "
  script=scripts/step31-extract-grammar-only.sh
  script_cmd="$script \
    $sorting \
    $pct"
  qopts="-N x${dom_abbrv}${pct}${sorting}"
  cmd="qsub $qopts $script_cmd"
  cachecmd extract_grammar_${pct}_${sorting} "$cmd" \
    $data_dependencies \
    $script \
    $rundir/grammar.gz \
    $rundir/test/final-bleu
done

exit

# Unsorted
# make sure to run the following command prior:
# cp -a ../grammar_unsorted/copy_these_rundirs/* runs
# Tune, test
sorting=unsorted
for pct in $PERCENTAGES ; do
  rundir=runs/${pct}_${sorting}
  data_dependencies="\
    `ls $DEV_CORPUS.$source_lang` \
    `ls $DEV_CORPUS.$target_lang` \
    `ls $TEST_CORPUS.$source_lang` \
    `ls $TEST_CORPUS.$target_lang`"
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
done


