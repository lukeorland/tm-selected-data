#!/bin/bash
#
# Extract the top number of lines correcsponding to the percentage (passed as
# $1 from the command line) of the total source segments from the unsorted
# segments.

#$ -cwd
#$ -S /bin/bash
#$ -l num_proc=1,h_vmem=1g,mem_free=1g,h_rt=1:00:00
#$ -M lorland1@jhu.edu
#$ -m eas

set -u
set -x
set -e
set -o pipefail

. config.sh

# Command-line arguments
percent_segs=$1

# Turn off globbing.
set -f

output_dir=data/selection

# Calculate the number of segments to retain based on the percent requested.
expression="$(cat data/selection/ppl_diffs_sorted_nodups.txt | wc -l) * $percent_segs / 100"
num_segs="$(echo $expression | bc)"

# Turn on globbing.
set +f

# SOURCE
head -n $num_segs $OUTDOMAIN_TEXT_SOURCELANG_PROCESSED \
	> $output_dir/outdomain_unsorted_$percent_segs.train.$source_lang

# TARGET
head -n $num_segs $OUTDOMAIN_TEXT_TARGETLANG_PROCESSED \
	> $output_dir/outdomain_unsorted_$percent_segs.train.$target_lang

