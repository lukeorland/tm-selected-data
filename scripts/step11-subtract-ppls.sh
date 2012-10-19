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

ppl_indomain=$1
ppl_outdomain=$2
ppl_diff=$3

# Combine perplexity differences, unprocessed/raw source-, and target-side text
# segments into a single file.
# "We partition N [non-in-domain set of segments] into tet segments (e.g.,
# sentences), and score the segments according to HI(s)-HN(s), selecting all
# text segments whose score is less than a threshold T".
# Then sort it (largest number is high perplexity against non-in-domain LM and
# much lower perplexity against in-domain LM).
# Then delete consecutive duplicates.
paste $ppl_indomain $ppl_outdomain \
	| awk -F '\t' '{print $1 - $2}' \
	> $ppl_diff
