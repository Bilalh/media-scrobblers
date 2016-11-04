media-scrobblers
================================

A deamon that scrobbles the current playing track in mpv-player when reaching 50%.

Usage
-----
`last_fm_scrobble_on_mplayer_played_50_with_info &`

Prerequisites
-------------
* mpv-player
* ruby 2+
* escape, taglib, rockstar gems

Install
-------
* Make a FIFO which can be made by doing `mkfifo ~/.mplayer/pipe`
* Set the path to your MPV FIFO in the source files if not using the above path
* run `make`
* run `make install`
* make sure that `/usr/local/bin` is in your `$PATH`


Bash function
----------
see `run_script.sh` for a bash function which is easier to use



taginfo directory
---
Displays information about audio files


Licence
-------
Apache 2.0

Authors
-------
* Bilal Hussain
