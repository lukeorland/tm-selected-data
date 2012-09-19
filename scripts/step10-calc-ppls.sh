#!/bin/bash
#
# This script subtracts the perplexity of the source-side text against the
# non-in-domain LM from the perplexity of the source-side text against the
# in-domain LM.
#
# It then prints out a file with the calculated perplexity difference, the
# source-side text segment, then the target-side text segment.
#
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

# Command-line arguments
srilm_dir=$1
outdomain_text_sourcelang_processed=$2
indomain_lm=$3

# Calculate the perplexity of the source-side non-in-domain text against the
# non-in-domain LM.
$srilm_dir/ngram -debug 1 -unk \
	-lm data/selection/outdomain_lm.gz \
	-ppl $outdomain_text_sourcelang_processed \
	| grep "zeroprobs.* logprob.* ppl.* ppl1" \
	| awk '{print $6}' \
	| head -n -1 \
	> data/selection/ppl_outdomain.txt


# Calculate the perplexity of the source-side non-in-domain text against the
# in-domain LM.
$srilm_dir/ngram -debug 1 -unk \
	-lm $indomain_lm \
	-ppl $outdomain_text_sourcelang_processed \
	| grep "zeroprobs.* logprob.* ppl.* ppl1" \
	| awk '{print $6}' \
	| head -n -1 \
	> data/selection/ppl_indomain.txt

