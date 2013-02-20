#!/usr/bin/env ruby
require 'rss'
require 'open-uri'
require 'redis'
require './my_credentials_and_settings.rb'
require './rdio.rb'

# Make sure redis is running first with redis-server
redis = Redis.new
rdio = Rdio.new([RDIO_CONSUMER_KEY, RDIO_CONSUMER_SECRET],
                [RDIO_TOKEN, RDIO_TOKEN_SECRET])

# Grab info from RSS feed
url = 'http://feeds2.feedburner.com/PitchforkBestNewAlbums'

open(url) do |rss|
  feed = RSS::Parser.parse(rss)

  # Iterate through items, cut them into artist and album and push the hash
  # into our array of tracks
  feed.items.each do |item|

    artist = item.title[/^(?:(?!:).)*/].strip
    album = item.title[/(?:(?!:).)*$/].strip

    # If our set of artists or our set of artist:title doesn't contain this
    # artist or album respectively, then we know we can add it!
    if redis.sadd("artists", artist) && redis.sadd("#{artist}:title", album) then

      # Unique id for key
      id = redis.incr("albums:nextID")

      # Create a hash for this album with the artist and the album
      redis.hmset "albums:#{id}", "artist", artist, "album", album

      # Search for "artist album"
      # never_or will ensure that we only get matches for the exact artist
      # and album combination
      search = rdio.call("search", { "query" => "#{artist} #{album}",
                                     "types" => "Album",
                                     "never_or" => "true" })

      # If our search works at all, continue
      res = search["result"]["results"] if search["status"] == "ok"

      unless res.length == 0 then
        if res[0]["canStream"] == true then
        # TODO save canStream to this album's hash

        # The playlist key needs the value of "key" from "getPlaylists"
          rdio.call("addToPlaylist", { "playlist" => RDIO_PLAYLIST_KEY,
                                       "tracks" => res[0]["trackKeys"].join(",") })
        end
      end
    else
      puts "#{artist}: #{album} already exists, silly"
      # TODO check hashes that previously had canStream = false
    end
  end
end
