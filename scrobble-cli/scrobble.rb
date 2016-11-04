#!/usr/bin/env ruby
# Scrobbles to last.fm
# Requires a file `lastfm.yml` with the following:
# ---
# api_key: <your api key>
# api_secret: <your secret>
#
# The first time the  program is run it will ask you to authorise it.
#
# Licensed under the Apache License, Version 2.0

require 'rockstar'
require 'optparse'

Options = Struct.new(:title, :artist, :album, :length, :album_artist,:track_number)

# Arg parser
class Parser
  def self.parse(options)
    args = Options.new()

    opt_parser = OptionParser.new do |opts|
      opts.banner = "Usage: scrobble.rb [options]"

      opts.on("--title=string")  {|n| args.title  = n}
      opts.on("--artist=string") {|n| args.artist = n}
      opts.on("--album=string")  {|n| args.album  = n}

      opts.on("--length=int", Integer) {|n| args.length       = n}
      opts.on("--album_artist=value")  {|n| args.album_artist = n}

      opts.on("--track_number=int", Integer) {|n| args.track_number = n}

      opts.on("-h", "--help", "Prints this help") do
        puts opts
        exit
      end
    end

    begin
      opt_parser.parse!(options)
      mandatory = [:title, :artist, :album, :length, :track_number, :album_artist]
      missing = mandatory.select{ |param| args[param].nil? }
      unless missing.empty?
        puts "Missing options: #{missing.join(', ')}"
        Parser.parse %w{ -h  }
        exit

      end
    rescue OptionParser::InvalidOption, OptionParser::MissingArgument
      puts $!.to_s
      exit
    end
    return args
  end
end

# Get the session key, store it if needed
def get_session_key(fp)
  data = YAML.load_file(fp)

  if  data.member? "session_key" then
    return data["session_key"]
  end

  a = Rockstar::Auth.new
  token = a.token

  puts
  puts "Please open\n http://www.last.fm/api/auth/?api_key=#{Rockstar.lastfm_api_key}&token=#{token}"
  puts
  puts "Press enter when done."

  gets

  session = a.session(token)
  data['session_key'] = session.key

  File.open(fp, 'w') {|f| f.write data.to_yaml }

  return session.key
end


if __FILE__ == $0
	opts = Parser.parse ARGV
	print "Args: #{opts}"


	fp=File.expand_path("~/.config/lastfm.yml")

	Rockstar.lastfm = YAML.load_file(fp)
	session_key=get_session_key(fp)

	Rockstar::Track.scrobble(
	  session_key: session_key,
	  track: opts.title,
	  artist: opts.artist,
	  album: opts.album,
	  albumArtist: opts.album_artist,
	  time: Time.new,
	  length: opts.length,
	  trackNumber: opts.track_number
	)

	# Love the Song :
	# l_status = Rockstar::Track.new('Coldplay', 'Viva La Vida').love(session_key)
	# puts "Love track status : #{l_status}"

	# Rockstar::Track.updateNowPlaying(
	#   session_key: session.key,
	#   track: "Viva La Vida",
	#   artist: "Coldplay",
	#   album: "Viva La Vida",
	#   time: Time.new,
	#   length: 244,
	#   track_number: 7
	# )
end
