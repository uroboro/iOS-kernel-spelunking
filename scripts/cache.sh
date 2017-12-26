#!//bin/sh

export PATH=$(pwd)/bin:$PATH

function print_help() {
	self=$1
	echo "$self [IPSW path]"
	echo "$self [device model] [ios build]"
	echo
	echo "Examples:"
	echo "\t $self iPodtouch_10.3.3_14G60_Restore.ipsw"
	echo "\t $self iPod7,1 14G60"
}

# Extraction functions

function extract_from_ipsw() {
	file="$1"
	kaches=$(unzip -l $file | grep kernelcache | awk '{ print $NF }')
	unzip $file $kaches &> /dev/null
	echo $kaches
}

function extract_from_url() {
	url="$1"

	tries=0
	err=1
	while [[ $err != 0 && $tries < 20 ]]; do
		list=$(partialzip -q -l $url)
		err=$?
		echo "[#] Couldn't open file: $(basename $url) (error=$err). Retrying..."
		((++tries))
	done
	if [[ $tries == 20 ]]; then
		echo "[#] Tried too many times, skipping"
		exit 2
	fi

	kaches=$(echo $list | tr ' ' '\n' | grep kernelcache)
	if [[ -z $kaches ]]; then
		echo "[#] No caches after downloading? Bailing"
		exit 1
	fi

	n=$(echo $kaches | wc -l | awk '{ print $1 }')
	echo "[#] Found $n kernelcache(s)"
	for f in $kaches; do
		if [[ ! -f $f || $(du $f | awk '{ print $1 }') == 0 ]]; then
			err=1
			while [[ $err != 0 ]]; do
				partialzip -q $url $f
				err=$?
				echo "[#] Couldn't download $f. Retrying..."
			done
		fi
	done
	echo $kaches
}

# Main program

if [ $# -eq 2 ]; then
	file=$(curl -s https://api.ipsw.me/v2.1/$1/$2/url)
	extract_from_url $file
elif [ $# -eq 1 ]; then
	file=$1
	if [[ $file == "http"* ]]; then
		extract_from_url $file
	else
		extract_from_ipsw $file
	fi
else
	print_help $0
	exit 0
fi
