#!/bin/sh

scripts/setup.sh

db_file=${1:-deviceDB/iPod7,1_10.txt}

IFS=$'\n' read -d '' -r -a devices < $db_file
lines=$(wc -l $db_file | awk '{ print $1 }')

for (( i = 0; i < $lines; i++ )); do
# for (( i = 0; i < 1; i++ )); do
	d=${devices[$i]}

	device=$(echo $d | awk '{ print $1 }')
	version=$(echo $d | awk '{ print $2 }')
	buildid=$(echo $d | awk '{ print $3 }')
	url=$(echo $d | awk '{ print $4 }')

	echo "$device on $version ($buildid): $url"

	if [[ ! -z "$(ls kernelDB/$device/$buildid/)" ]]; then
		mkdir -p offsetDB/$device/$buildid
		for f in kernelDB/$device/$buildid/*; do
			header=offsetDB/$device/$buildid/$(basename $f).h
			echo "// File automatically created with iOS-kernel-spelunking by uroboro" > $header
			echo "// Device: $device" >> $header
			echo "// Build: $buildid" >> $header
			echo >> $header
			scripts/offsets.sh $f | grep define >> $header
		done
	else
		kaches=$(scripts/cache.sh $url | grep kernelcache.release)
		for f in $kaches; do
			header=offsetDB/$device/$buildid/$(basename $f).h
			echo "// File automatically created with iOS-kernel-spelunking by uroboro" > $header
			echo "// Device: $device" >> $header
			echo "// Build: $buildid" >> $header
			echo >> $header
			scripts/offsets.sh $f | grep define >> $header
		done
	fi
done
