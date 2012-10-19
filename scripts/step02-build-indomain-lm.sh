#!/bin/bash
# Build a language model from non-in-domain text, with vocabulary restricted by
# that of the in-domain corpus.

#$ -cwd #$ -S /bin/bash
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
text=$2
lm=$3

$srilm_dir/ngram-count \
	-unk \
	-interpolate \
	-order 5 \
	-kndiscount \
	-text $text \
	-lm $lm

