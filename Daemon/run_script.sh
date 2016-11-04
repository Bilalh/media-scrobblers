#!/bin/bash
# This should be sourced

#
# can not be a script since it will not display more then one column
function mpm(){
	local dir=${MPM_DIR:-$HOME/Music/mpv/}
	[ ! -d "$dir" ] && echo "'$dir' does not exist" && return
	pushd "$dir"
	export USE_TAGINFO=true
	export DISPLAY_TRACK_INFO=true
	export USE_INCREMENT=true
	trap "popd; unset LC_ALL; unset IFS; unset USE_TAGINFO; unset DISPLAY_TRACK_INFO;unset USE_INCREMENT; trap -; return" SIGHUP SIGINT SIGTERM EXIT

	killall last_fm_scrobble_on_mplayer_played_50_with_info &> /dev/null

	export LC_ALL='C';
	IFS=$'\x0a';
	select OPT in `ls | egrep -ve 'cover|.*txt' | sort -bf` "." ". -shuffle" "Cancel"; do
		unset LC_ALL
		if [ "${OPT}" != "Cancel" ]; then
			name=""; args=""
			if [ "x${OPT}" = "x -shuffle" ]; then
				args="-shuffle";
			else
				name=${OPT};
			fi
    		last_fm_scrobble_on_mplayer_played_50_with_info &
			local conf=~/.mpv/input_with_last_fm_for_audio.conf
			pl_file="$(mktemp /tmp/mm.XXXXXX)"
			trap "rm ${pl_file}; popd; unset IFS; mend; unset USE_TAGINFO; unset DISPLAY_TRACK_INFO;unset USE_INCREMENT; trap -; return" SIGHUP SIGINT SIGTERM
			set -x
			find "$PWD/$name/"  \( -iname "*\.mp3" -o -iname "*\.m4a"  -o -iname "*\.flac" -o -iname "*\.ogg"  -o -iname "*\.wma"  \)  > $pl_file
			mpo "$@" ${args} --no-video -input conf=${conf}  -playlist $pl_file
			set +x
		fi
		break;
	done
}
