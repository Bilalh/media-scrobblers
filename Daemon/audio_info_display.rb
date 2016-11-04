#!/usr/bin/env ruby
require 'escape'
require_relative 'lastfm_from_mplayer_output'

output = $stdout

`echo 'print_text ${path}' >>  ~/.mplayer/pipe`
sleep 0.1
filepath = `tail -n1 ~/.mplayer/output`.chomp

exit unless filepath

m = read_using_taglib(filepath)
rest, seconds = m[:length].divmod 60
hours, minutes = rest.divmod 60
if hours > 0 then
    duration="%d:%02d:%02d" % [hours, minutes, seconds]
else
    duration="%d:%02d" % [minutes, seconds]
end

class String
  def colorise(color_code)
    "\e[#{color_code}m#{self}\e[0m"
  end

  def light_blue
    colorise(36)
  end
end

output.puts "# #{m[:artist]} [#{m[:albumArtist]}] - #{m[:title].light_blue} - #{m[:disc]}~#{m[:track]}@#{m[:album]} - #{duration}"
