#!/bin/sh

scripts/setup.sh

db_file=${1:-deviceDB/iPod7,1_10.txt}
echo $db_file
exit

IFS=$'\n' read -d '' -r -a devices < $db_file
lines=$(wc -l $db_file | awk '{ print $1 }')

for (( i = 0; i < $lines; i++ )); do
	d=${devices[$i]}

	device=$(echo $d | awk '{ print $1 }')
	version=$(echo $d | awk '{ print $2 }')
	buildid=$(echo $d | awk '{ print $3 }')
	url=$(echo $d | awk '{ print $4 }')

	echo "$device on $version ($buildid): $url"

	kaches=$(scripts/cache.sh $url | grep kernelcache.release)
	for f in $kaches; do
		scripts/offsets.sh $f
	done
done
