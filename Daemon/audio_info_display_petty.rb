#!/usr/bin/env ruby  -wU
require 'escape'

output = $stdout

`echo 'print_text ${path}' >>  ~/.mplayer/pipe`
sleep 0.1
filepath = `tail -n1 ~/.mplayer/output`.chomp
# filepath = filepath_with_name[/.*?=(.*)/,1]

`echo 'print_text ${=time-pos}' >>  ~/.mplayer/pipe`
sleep 0.1
time = `tail -n1 ~/.mplayer/output`
# time = time_with_name[/.*?=(.*)/,1]
time = time.to_f.round
# puts time, filepath
return unless time && filepath
output.puts('# ' + `/usr/local/bin/taginfo --pretty #{Escape.shell_command [filepath]} #{time}  2>/dev/null`)
