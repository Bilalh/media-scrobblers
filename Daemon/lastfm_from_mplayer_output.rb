#!/usr/bin/env ruby
# encoding: UTF-8
require 'taglib'
require 'rockstar'
require "yaml"
require "pp"
require 'escape'

METADATA_FILE  = File.expand_path("~/Movies/.Movie/OpeningP/_metadata.yaml")
LASTFM_KEY     = File.expand_path("~/.config/lastfm.yml")
PLAYCOUNT_FILE = ENV['PLAYCOUNT_FILE']  || File.expand_path("~/Music/playcount.yaml")

output         = if ENV['OUT_STD_ERR'] then $stderr else $stdout end

scrobbler_echo = ENV['SCROBBLER_ECHO']    || true
use_taginfo    = ENV['USE_TAGINFO']       || true

scrobbler_echo = false if !scrobbler_echo || scrobbler_echo == 'false'
use_taginfo    = false if !use_taginfo    || use_taginfo    == 'false'

use_increment  = ENV['USE_INCREMENT']     || false
use_increment  = false if !use_increment  || use_increment == 'false'

display = ENV['DISPLAY_TRACK_INFO']       || true
display = false if !display               || display == 'false'


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

def get_video_key(filepath)
    filename = File.basename filepath
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

    return key
end

def do_increment(filepath)
    counts =
    if File.exist? PLAYCOUNT_FILE then
         YAML::load(File.open PLAYCOUNT_FILE)
    else
         {}
    end
    i  = counts[filepath] || 0
    i += 1
    counts[filepath] = i

    File.open(PLAYCOUNT_FILE, 'w') do |f|
        f.write counts.to_yaml
    end
end

def read_using_taglib(filepath)
    m = {}
    TagLib::FileRef.open(filepath) do |fileref|
        unless fileref.null?
            tag = fileref.tag
            properties  = fileref.audio_properties
            m[:length]  =  properties.length
            m[:title]   = tag.title
            m[:artist]  = tag.artist
            m[:album]   = tag.album
            m[:track]   = tag.track
        end
    end

    if File.extname(filepath) == ".mp3" then
        TagLib::MPEG::File.open(filepath) do |file|
            tag   = file.id3v2_tag
            disc = tag.frame_list('TPOS').first
            temp = disc.to_s.to_i
            m[:disc] = temp if temp != 0

            albumArtist = tag.frame_list('TPE2').first
            t = albumArtist.to_s
            m[:albumArtist] = t if t
        end
    elsif File.extname(filepath) == ".m4a" then
        TagLib::MP4::File.open(filepath) do |file|
            map = file.tag.item_list_map
            disc_item = map['disk']
            if disc_item then
                disc = disc_item.to_int
                m[:disc] = disc if disc != 0
            end
            albumArtist_item = map['aART']
            if albumArtist_item then
                albumArtist = albumArtist_item.to_string_list
                m[:albumArtist] = albumArtist[0] if albumArtist and ! albumArtist.empty?
            end
        end
    end

    return m
end

if __FILE__ == $0
    now = Time.new
    Rockstar.lastfm = YAML.load_file(LASTFM_KEY)
    session_key=get_session_key(LASTFM_KEY)

    `echo 'print_text ${path}' >>  ~/.mplayer/pipe`
    sleep 0.1
    filepath = `tail -n1 ~/.mplayer/output`.chomp
    m = {}


    if use_taginfo then
        m = read_using_taglib(filepath)
        seconds = m[:length ]
    else
        metadata = YAML::load( File.open(METADATA_FILE))
        (output.puts "metadata file does not exist (#{METADATA_FILE})"; exit) unless metadata

        key = get_video_key(filepath)
        m = metadata[key] ||  metadata[key.downcase]
        (output.puts "# no metadata for '#{filename}' -- key:'#{key}'"; exit) unless  m

        if m[:length] then
            seconds = m[:length].split(":").inject{|a,b| a.to_i * 60 + b.to_i}
        else
            length_ms = `/usr/local/bin/mediaInfo --Inform='Audio;%Duration%' #{Escape.shell_command [filepath]}`.strip
            seconds = length_ms.to_i / 1000
        end

        if seconds == 0 or seconds >= 600
            seconds = 90
        end

    end
    do_increment(filepath) if use_increment

    data={  session_key: session_key,
      track:       m[:title],
      artist:      m[:artist],
      album:       m[:album],
      time:        now-seconds,
      length:      seconds,
      trackNumber: m[:track]}

    if m[:albumArtist] then
        data[:albumArtist] = m[:albumArtist]
    end

    ret= Rockstar::Track.scrobble(data)
    output.puts "# #{m[:artist]} [#{m[:albumArtist]}] - #{m[:title]} - #{m[:disc]}~#{m[:track]}@#{m[:album]} - #{ret}" if display
end
