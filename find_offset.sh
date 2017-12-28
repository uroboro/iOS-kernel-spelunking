#!/bin/sh

scripts/setup.sh

function make_header() {
	file="$1"
	device="$2"
	version="$3"
	buildID="$4"
	path="$5"
	header=$path/$(basename $file).h

	mkdir -p $path
	echo "// File automatically created with iOS-kernel-spelunking by uroboro" > $header
	echo "// Device: $device" >> $header
	echo "// Version: $version" >> $header
	echo "// Build: $buildID" >> $header
	echo >> $header
	echo "static void setOffsets_${device/,/_}_$buildID(void) {" >> $header
	scripts/offsets.sh $file | grep '=' >> $header
	echo "}" >> $header
}

db_file=${1:-deviceDB/iOS10/iPod7,1.txt}

IFS=$'\n' read -d '' -r -a devices < $db_file
lines=$(wc -l $db_file | awk '{ print $1 }')

for (( i = 0; i < $lines; i++ )); do
# for (( i = 0; i < 1; i++ )); do
	d=${devices[$i]}

	device=$(echo $d | awk '{ print $1 }')
	version=$(echo $d | awk '{ print $2 }')
	buildID=$(echo $d | awk '{ print $3 }')
	url=$(echo $d | awk '{ print $4 }')
	ios=$(echo $version | sed 's/\./ /g' | awk '{ print "iOS" $1 }')

	echo "$device on $version ($buildID): $url"

	if [[ ! -z "$(ls cacheDB/$ios/$device/$buildID/)" ]]; then
		kaches=$(find cacheDB/$ios/$device/$buildID -type f)
	else
		kaches=$(scripts/cache.sh $url | tr ' ' '\n' | grep kernelcache.release)
	fi

	offsetDBPath=offsetDB/$ios/$device/$buildID
	for f in $kaches; do
		make_header $f $device $version $buildID $offsetDBPath
	done
done
