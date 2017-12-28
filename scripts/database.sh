#!/bin/sh

function usable_devices() {
	pb="$1"
	file="$2"

	rm -r deviceDB
	devices=$($pb -c "Print :devices" $file | grep '^    [i]' | awk '{ print $1 }' | sort)
	for device in $devices; do
		builds=$($pb -c "Print :devices:$device:firmwares" $file | grep '^    [Dict]' | wc -l | awk '{ print $1 }')
		for (( i = 0; i < $builds; i++ )); do
			version=$($pb -c "Print :devices:$device:firmwares:$i:version" $file | sed 's/00000//')
			buildid=$($pb -c "Print :devices:$device:firmwares:$i:filename" $file | sed 's/.*_\(.*\)_Restore.*/\1/')
			url=$($pb -c "Print :devices:$device:firmwares:$i:url" $file)
			ios=$(echo $version | sed 's/\./ /g' | awk '{ print "iOS" $1 }')

			mkdir -p deviceDB/$ios
			echo "$device\t$version\t$buildid\t$url" >> deviceDB/$ios/$device.txt
		done
	done
}

plistTool=${1:-/usr/libexec/PlistBuddy}
if [ ! -f $plistTool ]; then
	echo "[#] No PlistBuddy compatible tool to work with. Bailing"
	exit 1
fi

curl -s https://api.ipsw.me/v2.1/firmwares.json/condensed -o firmwares.plist
plutil -convert xml1 firmwares.plist
usable_devices $plistTool firmwares.plist
