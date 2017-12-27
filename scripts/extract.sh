#!//bin/sh

export PATH=$(pwd)/bin:$PATH

kernelcache=/tmp/kernel

function print_help() {
	self=$1
	echo "$self [kernel cache] [output path]"
	echo
	echo "Example:"
	echo "\t $self kernelcache.release.n102 kernelcache.release.n102.dec"
}

function extract_kernel() {
	file_in="$1"
	file_out="$2"

	if [[ $(du $file_in | awk '{ printf $1 }') == "0" ]]; then
		echo "[#] Empty file. Bailing"
		return 1
	fi

	error=$(joker -dec $file_in 2>&1)
	err=$?
	if [[ ! -z $(echo $error | grep BVX) ]]; then
		img4 -image $file_in $file_out &> /dev/null
		return 0
	elif [[ ! -z $(echo $error | grep IMG3) ]]; then
		echo "[#] Can't handle img3 yet"
		# img3 -image $file_in $file_out
		return 1
	fi
	if [ ! -f $kernelcache ]; then
		if [[ ! -z $(echo $error | grep segmentation) ]]; then
			echo "[#] Segfault :/"
		else
			echo "[#] Unexpected error: $err"
		fi
		return 1
	else
		mv $kernelcache $file_out
	fi
	return 0
}

# Main program

if [ $# -eq 2 ]; then
	kache="$1"
	out="$2"
else
	print_help $0
	exit 0
fi

echo "[#] Extracting..."
extract_kernel $kache $out
if [[ $? != 0 ]]; then
	echo "[#] Failed extracting."
	exit 1
fi
