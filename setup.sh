# This script sets up the directory structure based on the user
# configuration.

. config.sh

dirs="data \
	data/selection \
	data/test \
	data/train \
	data/tune \
	log \
	runs"
for d in $dirs ; do \
	if [ ! -d "$d" ]; then
		mkdir -p $d
	fi
done

# Set up symlinks.
for f in \
	$INDOMAIN_TEXT_SOURCELANG_PROCESSED \
	$OUTDOMAIN_TEXT_SOURCELANG_PROCESSED \
	$OUTDOMAIN_TEXT_TARGETLANG_PROCESSED \
	$EXTRA_TRAINING_CORPUS_1 \
	$EXTRA_TRAINING_CORPUS_2 \
	$EXTRA_TRAINING_CORPUS_3 ; do

	rm -f data/train/$(basename $f)*
	ln -s $f data/train/
done

rm -f data/tune/$(basename $DEV_CORPUS)
ln -s $DEV_CORPUS data/tune/

rm -f data/test/$(basename $TEST_CORPUS)
ln -s $TEST_CORPUS data/test/

ln -s $INDOMAIN_LM data/selection/indomain_lm.gz
