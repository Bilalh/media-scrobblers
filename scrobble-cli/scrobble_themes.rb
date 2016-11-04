#!/usr/bin/env ruby
require_relative "scrobble"
require 'rockstar'
require 'pp'
require 'set'
require "yaml"

METADATA_FILE  = "/Users/bilalh/Movies/.Movie/OpeningP/_metadata.yaml"
METADATA_EXTRA = "/Users/bilalh/Movies/.Movie/OpeningP/_metadata_extra.yaml"
MISSING_FILE   = "/Users/bilalh/Movies/.Movie/OpeningP/_missing.yaml"
HISTORY_FILE   = "/Users/bilalh/Movies/.Movie/OpeningP/_mhistory_c.yaml"
DATA_FILE      = "/Users/bilalh/Movies/.Movie/OpeningP/_mdata.yaml"
yml=File.join(File.dirname(__FILE__), 'lastfm.yml')
Rockstar.lastfm = YAML.load_file(yml)
session_key=get_session_key(yml)

display=true
output= if ENV['OUT_STD_ERR'] then $stderr else $stdout end
metadata = YAML::load( File.open(METADATA_FILE))

if File.exists? METADATA_EXTRA  then
    metadata.merge!( YAML::load( File.open(METADATA_EXTRA)) || {})
end

if File.exists? MISSING_FILE  then
	missing = YAML::load( File.open(MISSING_FILE)) || {}
else
	missing = {}
end

if File.exists? HISTORY_FILE  then
	hist = YAML::load( File.open(HISTORY_FILE))
else
	hist = {}
end

if File.exists? DATA_FILE  then
	data = YAML::load( File.open(DATA_FILE))
else
	data = {uncategorised_index:1, total_plays:0, uncategorised_plays:0}
end

last_scrobble=10000 # no maxint in ruby
prev_name=""


loop{
	video_title= %x[osascript -e 'tell application "Google Chrome" to return title of active tab of front window']
	song = video_title.split("~")[-1].strip
    song.sub!(" - YouTube","")
	now = Time.new

	script = File.expand_path(File.dirname(__FILE__)) + "/get_video_time.sh"
	times_str= `#{script}`
	if times_str == "missing value\n" then
		output.puts("could not find the current/end time") if display
		sleep 10
		next
	end
	# [current, max]
	current,length= times_str.split(",").map{|a| a.to_i }

	if (current >= length/2  or current >=300 ) and (video_title != prev_name or  last_scrobble >= current )

		ret =nil
		if metadata[song.downcase] then
			m = metadata[song.downcase]
			if m[:length] then
				seconds = m[:length].split(":").inject{|a,b| a.to_i * 60 + b.to_i}
			else
				seconds = length
			end

			ret= Rockstar::Track.scrobble(
			  session_key: session_key,
			  track:       m[:title],
			  artist:      m[:artist],
			  album:       m[:album],
			  albumArtist: m[:albumArtist] || m[:artist],
			  time:        now-seconds,
			  length:      seconds,
			  trackNumber: m[:track]
			)
			output.puts "# #{m[:artist]} - #{m[:title]} - #{m[:album]} - #{ret}" if display
		else
			album_sub = "Uncategorised %02d" % data[:uncategorised_index]
			ret= Rockstar::Track.scrobble(
			  session_key: session_key,
			  track:       song,
			  artist:      "aThemes",
			  albumArtist: "aThemes",
			  album:       album_sub,
			  time:        now-length,
			  length:      length,
			  trackNumber: 1
			)

			output.puts "# Missing: #{video_title.strip} ~~~ #{song.downcase} ~~ Uidx#{data[:uncategorised_index]} ~~  #{ret}" if display

			if missing[song.downcase] then
				d = missing[song.downcase]
				d[:count] += 1
				d[:titles].add(video_title.strip)
			else
				d = { count: 1, titles: Set.new([video_title.strip])  }
				missing[song.downcase]=d
			end

			data[:uncategorised_plays]+=1
			open(MISSING_FILE, 'w') do |f|
			  f.write(YAML.dump(missing))
			end
		end

		last_scrobble = current

		if hist[song] then
			hist[song]+=1
		else
			hist[song]=1
		end

		data[:total_plays] += 1

		if data[:uncategorised_plays].to_f / data[:uncategorised_index] == 20 then
			data[:uncategorised_index]+= 1
		end

		open(HISTORY_FILE, 'w') do |f|
		  f.write(YAML.dump(hist))
		end

		open(DATA_FILE, 'w') do |f|
		  f.write(YAML.dump(data))
		end

		prev_name = video_title
	end
	sleep 10
}

