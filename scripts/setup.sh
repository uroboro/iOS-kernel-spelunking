#!/bin/sh

function install_radare2() {
	brew ls --versions radare2 > /dev/null
	if [ ! $? -eq 0 ]; then
		brew update &> /dev/null
		brew install radare2 &> /dev/null
	fi
}

function install_partialzip() {
	if [[ ! -f bin/partialzip ]]; then
		echo "[#] Cloning partial-zip repo..."
		git clone https://github.com/uroboro/partial-zip &> /dev/null
		pushd partial-zip &> /dev/null
		echo "[#] Building..."
		cmake . &> /dev/null
		make &> /dev/null
		popd &> /dev/null
		mkdir -p bin
		cp partial-zip/partialzip bin/
		rm -rf partial-zip
		echo "[#] Done!"
	fi
}

function install_joker() {
	if [[ ! -f bin/joker ]]; then
		echo "[#] Downloading joker..."
		curl -s http://newosxbook.com/tools/joker.tar -o /tmp/joker.tar
		echo "[#] Extracting..."
		tar -xf /tmp/joker.tar joker.universal
		mkdir -p bin
		mv joker.universal bin/joker
		rm /tmp/joker.tar
		echo "[#] Done!"
	fi
}

function install_img4tool() {
	if [[ ! -f bin/img4 ]]; then
		echo "[#] Cloning img4tool repo..."
		git clone --recursive https://github.com/uroboro/img4tool &> /dev/null
		pushd img4tool &> /dev/null
		echo "[#] Building..."
		make img4 &> /dev/null
		popd &> /dev/null
		mkdir -p bin
		cp img4tool/img4 bin/
		rm -rf img4tool
		echo "[#] Done!"
	fi
}

# Main program

install_radare2
install_partialzip
install_joker
install_img4tool
