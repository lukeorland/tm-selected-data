#!/bin/bash
#
# This script prints out a file with the calculated perplexity difference, the
# source-side text segment, then the target-side text segment, all tab-delimited.
# Finally, it sorts the file by the perplexity difference value.

#$ -cwd
#$ -S /bin/bash
#$ -l num_proc=1,h_vmem=8g,mem_free=8g,h_rt=24:00:00
#$ -e log
#$ -o log
#$ -M lorland1@jhu.edu
#$ -m eas

set -u
set -x
set -e
set -o pipefail

outdomain_text_sourcelang_processed=$1
outdomain_text_targetlang_processed=$2

# Combine perplexity differences, unprocessed/raw source-, and tart-side text
# segments into a single file.
# "We partition N [non-in-domain set of segments] into tet segments (e.g.,
# sentences), and score the segments according to HI(s)-HN(s), selecting all
# text segments whose score is less than a threshold T".
# Then sort it (largest number is high perplexity against non-in-domain LM and
# much lower perplexity against in-domain LM).
# Then delete consecutive duplicates.
paste data/selection/ppl_indomain.txt data/selection/ppl_outdomain.txt \
	| awk -F '\t' '{print $1 -$2}' \
	| paste - $outdomain_text_sourcelang_processed \
	| paste - $outdomain_text_targetlang_processed \
	| sort -n \
	| uniq \
	> data/selection/ppl_diff_source_target_sorted_nodups.txt
