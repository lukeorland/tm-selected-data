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
outdomain_text=$2
outdomain_lm=$3
indomain_lm=$4
ppl_outdomain=$5
ppl_indomain=$6

# Calculate the perplexity of the non-in-domain text against the
# LM.
$srilm_dir/ngram -debug 1 -unk \
	-lm $outdomain_lm \
	-ppl $outdomain_text \
	| grep "zeroprobs.* logprob.* ppl.* ppl1" \
	| awk '{print $6}' \
	| head -n -1 \
	> $ppl_outdomain

# Calculate the perplexity of the source-side non-in-domain text against the
# in-domain LM.
$srilm_dir/ngram -debug 1 -unk \
	-lm $indomain_lm \
	-ppl $outdomain_text \
	| grep "zeroprobs.* logprob.* ppl.* ppl1" \
	| awk '{print $6}' \
	| head -n -1 \
	> $ppl_indomain
