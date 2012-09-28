# Your ~/.bashrc should contain (similar) values for the following environment
# variables:
#
# LANG=en_US.UTF-8
# LC_ALL=en_US.UTF-8
# JOSHUA=/path/to/joshua
# HADOOP_VERSION="0.20.203.0"
# HADOOP=/path/to/apache/hadoop
# HADOOP_CONF_DIR=$HADOOP/conf/apache-mr/mapreduce
# JAVA_HOME=/usr/java/default

set -e
set -o pipefail

# Source and target language file extensions
source_lang=fr
target_lang=en

# User-modifiable configurations
SRILM_DIR=$HOME/.local/bin
PERCENTAGES="5 10 15 20"  # 0 percent gets done implicitly.

# Preprocessed (normalized, tokenized, lowercased, blanks removed) source side
# of in-domain corpus
INDOMAIN_CORPUS=$HOME/corpora/ws12-damt-data-pp/Subs/train.no-doc-boundary.normal.cleaned
INDOMAIN_TEXT_SOURCELANG_PROCESSED=$INDOMAIN_CORPUS.$source_lang
INDOMAIN_TEXT_TARGETLANG_PROCESSED=$INDOMAIN_CORPUS.$target_lang

# Source-side non-in-domain corpus
OUTDOMAIN_CORPUS=$HOME/corpora/ws12-damt-data-pp/hansard/train.no-doc-boundary.normal.cleaned

# Source-side non-in-domain corpus text used to select parallel training data
OUTDOMAIN_TEXT_SOURCELANG_PROCESSED=$OUTDOMAIN_CORPUS.$source_lang
OUTDOMAIN_TEXT_TARGETLANG_PROCESSED=$OUTDOMAIN_CORPUS.$target_lang

# These are not currently used.
#EXTRA_TRAINING_CORPUS_1=data/blank
#EXTRA_TRAINING_CORPUS_2=data/blank
#EXTRA_TRAINING_CORPUS_3=data/blank

DEV_CORPUS=$HOME/corpora/ws12-damt-data-pp/Subs/dev1.short.no-doc-boundary.normal.unseen
TEST_CORPUS=$HOME/corpora/ws12-damt-data-pp/Subs/test1.short.no-doc-boundary.normal.unseen
