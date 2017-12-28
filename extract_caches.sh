#!/bin/sh

scripts/setup.sh

db_file=${1:-deviceDB/iOS10/iPod7,1.txt}

IFS=$'\n' read -d '' -r -a devices < $db_file
lines=$(wc -l $db_file | awk '{ print $1 }')

for (( i = 0; i < $lines; i++ )); do
	d=${devices[$i]}

	device=$(echo $d | awk '{ print $1 }')
	version=$(echo $d | awk '{ print $2 }')
	buildID=$(echo $d | awk '{ print $3 }')
	url=$(echo $d | awk '{ print $4 }')
	ios=$(echo $version | sed 's/\./ /g' | awk '{ print "iOS" $1 }')

	echo "$device on $version ($buildID): $url"
	kernelDBPath=kernelDB/$ios/$device/$buildID
	cacheDBPath=cacheDB/$ios/$device/$buildID
	if [[ -d $kernelDBPath ]]; then
		for f in $(ls $kernelDBPath); do
			if [[ ! -f $cacheDBPath/$f || $(du $cacheDBPath/$f | awk '{ printf $1 }') == "0" ]]; then
				mkdir -p $cacheDBPath
				scripts/extract.sh $kernelDBPath/$f $cacheDBPath/$f
			fi
		done
	fi
done
