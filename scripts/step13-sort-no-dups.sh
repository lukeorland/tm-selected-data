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

# Then sort it (largest number is high perplexity against non-in-domain LM and
# much lower perplexity against in-domain LM).
# Then delete consecutive duplicates.
cat data/selection/ppl_diffs_sum.txt \
	| sort -n \
	| uniq \
	> data/selection/ppl_diffs_sum_sorted_nodups.txt
