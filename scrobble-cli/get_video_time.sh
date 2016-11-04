#!/bin/bash
set -o nounset
export OUR="$( cd "$( dirname "$0" )" && pwd )";

osascript -e 'tell application "Google Chrome" to tell front window to execute active tab javascript "v=document.getElementsByTagName('\''video'\'')[0]; Math.floor(v.currentTime) + '\'','\'' + Math.floor(v.duration)"'
