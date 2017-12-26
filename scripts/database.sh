#!/bin/sh

function usable_devices() {
	file="$1"
	pb=/usr/libexec/PlistBuddy

	mkdir -p sorted
	devices=$($pb -c "Print :devices" $file | grep '^    [i]' | awk '{ print $1 }' | sort)
	for device in $devices; do
		builds=$($pb -c "Print :devices:$device:firmwares" $file | grep '^    [Dict]' | wc -l | awk '{ print $1 }')
		for (( i = 0; i < $builds; i++ )); do
			version=$($pb -c "Print :devices:$device:firmwares:$i:version" $file | sed 's/00000//')
			buildid=$($pb -c "Print :devices:$device:firmwares:$i:filename" $file | sed 's/.*_\(.*\)_Restore.*/\1/')
			url=$($pb -c "Print :devices:$device:firmwares:$i:url" $file)

			ios=$(echo $version | sed 's/\./ /g' | awk '{ print "_" $1 }')
			echo "$device\t$version\t$buildid\t$url" >> sorted/$device$ios.txt
		done
	done
}

if [ ! -f /usr/libexec/PlistBuddy ]; then
	echo "[#] No PlistBuddy to work with. Bailing"
	exit 1
fi

rm -r sorted
curl -s http://api.ipsw.me/v2.1/firmwares.json/condensed -o firmwares.plist
usable_devices firmwares.plist
