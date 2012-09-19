# This script sets up the directory structure based on the user
# configuration.

. config.sh

dirs="data \
	data/selection \
	log \
	runs"
for d in $dirs ; do \
	if [ ! -d "$d" ]; then
		mkdir -p $d
	fi
done
