#!/bin/bash

set -x

. config.sh

num=$(cat $INDOMAIN_TEXT_SOURCELANG_PROCESSED | wc -l)

head -n $num $OUTDOMAIN_TEXT_SOURCELANG_PROCESSED \
  > data/selection/outdomain_segs.$source_lang
head -n $num $OUTDOMAIN_TEXT_TARGETLANG_PROCESSED \
  > data/selection/outdomain_segs.$target_lang
