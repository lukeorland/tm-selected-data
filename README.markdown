The scripts in these directories build and train an in-domain translation model using a Moore & Lewis-inspired approach.

# Before getting started,
1.  Preprocess in- and no-in-domain corpora.
2.  Build an in-domain language model and assign it location to the
    variable INDOMEAIN_TEXT_SOURCELANG_PROCESSED in
    config/config_step00.sh .
3.  Set the paths in the rest of the configuration files under the
    config/ directory.
4.  Add the environment variable $JOSHUA, which should point to
    somewhere like /export/common/SCALE12/mt/joshua .

Then, run ./Bashpipe.sh to extract training segments in The Moore &
Lewis Way. A grammar is also extracted, and the full pipeline is run.

The resulting language models are the grammar.gz files found in the
directories under the runs/ directory.

# Descriptions of the steps:

## step00

Extract the source-side vocabulary from the in-domain corpus

## step01

FIXME: Build a language model from non-in-domain text, with vocabulary
restricted by that of the in-domain corpus.

## step10

Subtracts the perplexity of the source-side text  against the
non-in-domain LM from the perplexity of the source-side text against the
non-in-domain LM from the perplexity of the source-sie text against the
in-domain LM.

It then prints out a file with the calculated perplexity difference, the
source-side text segment, then the target-side text segment, all
tab-delimited.

## step11

Combine perplexity differences, unprocessed/raw source-, and target-sie
text segments into a single file.
"We partition N [non-in-domain set of segments] into text segments
(e.g., sentences), and score the segments according to HI(s)-HN(s),
selecting all text segments whose score is less than a threshold T".

Then sort it (largest number is high perplexity against non-in-domain LM
and much lower perplexity against in-domain LM).
Then delete consecutive duplicates.

## step20

Extract the top number of lines correcsponding to the percentage (passed
as $1 from the command line) of the totatl source segments from the list
of segments sorted by the perplexity difference.

## step21

Extract the top number of lines corresponding to the percentage (passed
as $1 from the command line) of the total source segments from the
unsorted segments.

## step30

Run the full pipeline, building and training the translation model
against selected (sorted) data.

## step31

Run the full pipeline, building and training the translation model
against random (unsorted) data.
