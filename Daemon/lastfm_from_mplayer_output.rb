#!/usr/bin/env ruby  -wU
# encoding: UTF-8
require "yaml"
require "pp"
require 'escape'

LASTFM_SUBMIT  = '/usr/local/bin/lastfmsubmit'
METADATA_FILE  = "/Users/bilalh/Movies/.Movie/OpeningP/_metadata.yaml"
output         = if ENV['OUT_STD_ERR'] then $stderr else $stdout end


scrobbler_echo = ENV['SCROBBLER_ECHO']    || true
use_taginfo    = ENV['USE_TAGINFO']       || true

scrobbler_echo = false if !scrobbler_echo || scrobbler_echo == 'false'
use_taginfo    = false if !use_taginfo    || use_taginfo    == 'false'

use_increment  = ENV['USE_INCREMENT']      || false
use_increment  = false if !use_increment   || use_increment == 'false'

display = ENV['DISPLAY_TRACK_INFO']       || true
display = false if !display || display == 'false'

playcount_file = ENV['PLAYCOUNT_FILE'] || File.expand_path("~/Music/playcount.yaml")


`echo 'print_text ${path}' >>  ~/.mplayer/pipe`
sleep 0.1
# filepath_with_name = `tail -n1 ~/.mplayer/output`
# filepath = filepath_with_name[/.*?=(.*)/,1]
filepath = `tail -n1 ~/.mplayer/output`.chomp
m = {}

if use_taginfo then
	arr = `/usr/local/bin/taginfo --short #{Escape.shell_command [filepath] } 2>/dev/null`.split(/\n/)
	(output.puts "# No Tag Info for #{filepath}";exit ) if arr.length == 0
	m = {title:arr[0], album:arr[1], artist:arr[2], length:arr[3]}
	output.puts('# ' + `taginfo --info #{Escape.shell_command [filepath]} 2>/dev/null`) if display

else
	filename = File.basename filepath
	metadata = YAML::load( File.open(METADATA_FILE)) || (output.puts "no metadata file"; exit)

	name_only=File.basename(filename, File.extname(filename)).strip
	name_only.sub!(/ %[^%]+$/, "")
	remove=["720", "1080", "flac", "sub", "nc"]

	key = name_only
	remove.each do |idea|
		key.sub!(" " + idea, " ")
	end

	key.sub!(/(?: -)? NCED ?(\d+)/, ' ed \1')
	key.sub!(/(?: -)? NCOP ?(\d+)/, ' op \1')
	# Account for the case when a number is not given
	key.sub!(/(?: -)? NCED/, ' ed 1')
	key.sub!(/(?: -)? NCOP/, ' op 1')
	key.gsub!(/  +/," ")
	key.strip!

	m = nil
	if metadata[key] then
		m = metadata[key]
	else
		puts "# no metadata for '#{filename}' -- key:'#{key}'"
		exit
	end

	m[:length] = `/usr/local/bin/mediaInfo --Inform='Video;%Duration/String3%' #{Escape.shell_command [filepath]} | sed "s/\.[0-9][0-9]*$//"`.strip

	if m[:length].empty?
		m[:length] = "1:30"
	else
		seconds = m[:length].split(":").inject{|a,b| a.to_i * 60 + b.to_i}
		m[:length] = "1:30" if seconds >= 600
	end

	output.puts "# #{m[:artist]} - #{m[:title]} - #{m[:album]}" if display
	filepath = filename
end

if use_increment then
	counts =
	if File.exist? playcount_file then
		 YAML::load(File.open playcount_file)
	else
		 {}
	end
	i  = counts[filepath] || 0
	i += 1
	counts[filepath] = i


	File.open(playcount_file, 'w') do |f|
		f.write counts.to_yaml
	end

end


output.puts %{# #{LASTFM_SUBMIT} -e utf8 -a "#{m[:artist]}" -b "#{m[:album]}" --title "#{m[:title]}" -l "#{m[:length]}"} if scrobbler_echo
# scrobbles the track

artist, album, title = Escape.shell_single_word(m[:artist]),  Escape.shell_single_word(m[:album]),  (Escape.shell_single_word m[:title])
# puts "# #{artist}, #{album}, #{title}"

output.puts `kill $(ps aux | grep lastfmsubmitd | grep -v grep  | awk '{print $2}') &>/dev/null;\
#{LASTFM_SUBMIT} -e utf8 -a #{artist} -b #{album} --title #{title} -l "#{m[:length]}"; /usr/local/bin/lastfmsubmitd&`


