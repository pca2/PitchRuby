#!/usr/bin/env ruby
require 'rss'
require 'open-uri'
require 'redis'
require './my_credentials_and_settings.rb'
require './rdio.rb'

# Make sure redis is running first with redis-server
@redis = Redis.new
@rdio = Rdio.new([RDIO_CONSUMER_KEY, RDIO_CONSUMER_SECRET],
                 [RDIO_TOKEN, RDIO_TOKEN_SECRET])

def set_streamable(id, state)
  if state == true then
    @redis.srem("albums:unavailable", id)
  else
    @redis.sadd("albums:unavailable", id)
  end
end

def find_album(artist, title)
  # Search for "artist title"
  # never_or will ensure that we only get matches for the exact artist
  # and title combination
  search = @rdio.call("search", { "query" => "#{artist} #{title}",
                      "types" => "Album",
                      "never_or" => "true" })

  # If our search works at all, continue
  if search["status"] == "ok"
    puts "Search worked"
    res = search["result"]["results"]
    if res.length > 0 then
      return res
    else
      puts "But no matches found"
      return []
    end
  else
    puts "Error searching for #{artist}: #{title}"
    puts search
    return []
  end
end

def store_album(artist, title)
  # Unique id for key
  id = @redis.incr("albums:nextID")

  # Add this artist:album key for lookups
  @redis.set("albums:#{artist}:#{title}", id)

  # Create a hash for this album with the artist and the title
  @redis.hmset( "albums:#{id}", "id", id, "artist", artist, "title", title )

  # Initially add it to the unavailable albums list
  set_streamable(id, false)

  return id
end

def add_album(id)
  # Find that album
  album = @redis.hgetall("albums:#{id}")
  artist = album['artist']
  title = album['title']

  res = find_album(artist, title)
  if res.length > 0 && res[0]["canStream"] == true then
    # Save this album to the set of available albums
    set_streamable(id, true)
    puts "#{artist}: #{title} is available!"

    # The playlist key needs the value of "key" from "getPlaylists"
    resp = @rdio.call("addToPlaylist", { "playlist" => RDIO_PLAYLIST_KEY,
                      "tracks" => res[0]["trackKeys"].join(",") })

    if resp["status"] == "ok"
      puts "Oh yeah we done added #{artist}: #{title}!"
    else
      puts "Adding that #{title} didn't work"
      puts resp
    end

  else
    # Save this album to the set of unavailable albums
    set_streamable(id, false)
    puts "#{artist}: #{title} is unavailable :("
  end
end

# Grab info from RSS feed
url = 'http://feeds2.feedburner.com/PitchforkBestNewAlbums'

# Get the most recent post we processed from the db
latest_post = @redis.get("albums:latest_post").to_i

# Here's where the feed parsing goes down
open(url) do |rss|
  feed = RSS::Parser.parse(rss)

  # Iterate through items
  feed.items.each do |item|

    # Get the time of posting and convert it to unix timestamp
    post_time = item.pubDate.to_i

    # Loop until we hit the latest post we did last time
    break if post_time == latest_post

    puts "New music, woo!"

    # Parse out artists and titles
    artist = item.title[/^(?:(?!:).)*/].strip
    album = item.title[/(?:(?!:).)*$/].strip
    # I don't care if it's an EP, but Rdio doesn't usually append this
    album.gsub!(" EP", "")

    # If our set of artists or our set of artist:albums doesn't contain this
    # artist or album respectively, then we know we can add it!
    if not @redis.exists("albums:#{artist}:#{album}") then
      id = store_album(artist, album)
      add_album(id)
    end
  end
  # Set the latest_post to the first post in the feed
  @redis.set("albums:latest_post", feed.items[0].pubDate.to_i)
end

# Check our unavailable albums for availability
puts "Checking if our unavailable albums have become available..."
unavail = @redis.smembers("albums:unavailable")
unavail.each do |u|
  add_album(u)
end

u_tally = @redis.scard("albums:unavailable")
puts "There are currently #{u_tally} albums still unavailable on Rdio"

# I could mess with redis settings to make it save more frequently
# or I could just explicitly call save...
@redis.save
