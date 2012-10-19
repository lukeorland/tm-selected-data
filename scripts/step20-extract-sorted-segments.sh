#!/bin/bash
#
# This script extracts the top number of lines corresponding to the percentage
# (passed as $1 from the command line) of the total source segments from the
# list of segments sorted/unsorted by perplexity difference.

#$ -cwd
#$ -S /bin/bash
#$ -l num_proc=1,h_vmem=1g,mem_free=1g,h_rt=1:00:00
#$ -M lorland1@jhu.edu
#$ -m eas

set -u
set -x

# Command-line arguments
percent_segs=$1
source_dest=$2
target_dest=$3

# turn off globbing.
set -f

output_dir=data/selection

# Calculate the number of segments to retain based on the percent requested.
expression="$(cat data/selection/ppl_diffs_sum_sorted_nodups.txt | wc -l) * $percent_segs / 100"
num_segs="$(echo $expression | bc)"

# turn on globbing.
set +f

cat data/selection/ppl_diffs_sum_sorted_nodups.txt \
	| head -n $num_segs \
	| head -n $num_segs \
	| tee \
	>(awk -F '\t' '{print $2}' \
		> $source_dest) \
	>(awk -F '\t' '{print $3}' \
		> $target_dest) \
	> /dev/null
