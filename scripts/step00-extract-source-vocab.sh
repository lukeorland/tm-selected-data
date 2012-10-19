#!/bin/bash

#$ -cwd
#$ -S /bin/bash
#$ -e log
#$ -o log
#$ -M lorland1@jhu.edu
#$ -m eas

# Extract the source-side vocabulary from the in-domain corpus
set -u
set -x
set -e
set -o pipefail

# Command-line arguments
srilm_dir=$1
indomain_text_sourcelang_processed=$2

$srilm_dir/ngram-count -text $indomain_text_sourcelang_processed -write-order 1 -write data/selection/indomain_sourcelang.1cnt
awk '$2>1' data/selection/indomain_sourcelang.1cnt | cut -f1 | sort > data/selection/indomain_sourcelang.vocab
