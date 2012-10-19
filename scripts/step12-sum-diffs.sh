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

paste data/selection/ppl_source_diff.txt data/selection/ppl_target_diff.txt \
	| awk -F '\t' '{print $1 + $2}' \
	| paste - $outdomain_text_sourcelang_processed \
	| paste - $outdomain_text_targetlang_processed \
	> data/selection/ppl_diffs_sum.txt
