# iOS-kernel-spelunking

A bunch of scripts to download and get specific offsets in an iOS kernel cache.

---

Scripts:

- setup.sh: Installs radare2, joker, img4 and partialzip to local `bin` folder.

- database.sh: Downloads database from ipsw.me and saves device, version, buildID and url to `deviceDB` folder.

- cache.sh: Extracts or downloads kernel caches from an IPSW or a device model and iOS build pair. Outputs the list of extracted files.

- extract.sh: Decrypts/decompresses a kernel cache to a specified path.

- offsets.sh: Calculates addresses for past and present symbols for [v0rtex](https://github.com/Siguza/v0rtex)
