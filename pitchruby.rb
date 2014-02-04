#!/usr/bin/env ruby
#A simple script to parse the RSS feed of Pitchfork's Best New Albums feature and attempt to add them to an Rdio playlist if available
#Authors: Alex Brown (alexpbrown) & Carleton Atwater (pca2)
$:.unshift File.expand_path(File.dirname(__FILE__)) #add containing folder to load path
DIR = File.expand_path(File.dirname(__FILE__)) #path to containing folder
require 'rss'
require 'open-uri'
require 'data_mapper'
require 'my_credentials_and_settings.rb'
require 'rdio.rb'
DataMapper::setup(:default, "sqlite://#{DIR}/pitchruby.db")

class Album
  include DataMapper::Resource
  property :id, Serial, :required => true
  property :artist, String, :required => true
  property :album, String, :required => true
  property :canStream, Boolean, :required => true
  property :pubDate, Time
  property :created_at, DateTime
end

DataMapper.finalize.auto_upgrade!


@rdio = Rdio.new([RDIO_CONSUMER_KEY, RDIO_CONSUMER_SECRET],
                 [RDIO_TOKEN, RDIO_TOKEN_SECRET])

def set_streamable(id, state)
  if state == true then
Album.get(id).update(:canStream => true)
  else
Album.get(id).update(:canStream => false)
  end
end

def find_album(artist, title)
  #Finds album on Rdio
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

def store_album(artist, title, post_time)
  #stores album in DB
  Album.create(:artist => artist, :album => title, :pubDate => post_time,  :canStream => false)
  return Album.last.id
end

def add_album(id)
  #Adds album to playlist
  # Find that album
  album_to_add = Album.get(id)
  artist = album_to_add.artist
  title = album_to_add.album

  res = find_album(artist, title)
  if res.length > 0 && res[0]["canStream"] == true then
    # Save this album to the set of available albums
    set_streamable(id, true)
    puts "#{artist}: #{title} is available!"
    new_album_tracks = res[0]["trackKeys"]

    #Get current track listing of playlist as plist_tracks array
    plist_search = @rdio.call("get", {"keys" => RDIO_PLAYLIST_KEY, "extras" => "tracks"})
    plist_tracks = []
    plist_search["result"][RDIO_PLAYLIST_KEY]["tracks"].each { |x| plist_tracks.push(x["key"]) }

    #add new album to playlist. API only allows for adding it to the end of the list.
    @rdio.call("addToPlaylist", { "playlist" => RDIO_PLAYLIST_KEY,
                      "tracks" => new_album_tracks.join(",") })
    #Create new tracklist order by concatenating original track listing to the end of list of new albums tracks
    new_plist_tracks = new_album_tracks.concat(plist_tracks)
    #save new tracklist order
    resp = @rdio.call("setPlaylistOrder", {"playlist" => RDIO_PLAYLIST_KEY,
      "tracks" => new_plist_tracks.join(",") })

    if resp["status"] == "ok"
      puts "Oh yeah we done added #{artist}: #{title} to the playlist"
    else
      puts "Adding #{title} didn't work"
      puts resp
    end

  else
    # Save this album to the set of unavailable albums
    set_streamable(id, false)
    puts "#{artist}: #{title} is unavailable :("
  end
end

#END of methods, begin script


# Grab info from RSS feed
url = 'http://pitchfork.com/rss/reviews/best/albums/'

# Get the most recent post we processed from the db
latest_post = Album.max(:pubDate).to_time
# Here's where the feed parsing goes down
open(url) do |rss|
  feed = RSS::Parser.parse(rss)

  # Iterate through items
  feed.items.each do |item|

   # Get the time of posting
    post_time = item.pubDate

    # Loop until we hit the latest post we did last time
    if post_time == latest_post
      puts "No new music :("
      break
    end

    puts "New music, woo!"

    # Parse out artists and titles
    artist = item.title[/^(?:(?!:).)*/].strip
    album = item.title[/(?:(?!:).)*$/].strip
    # I don't care if it's an EP, but Rdio doesn't usually append this
    album.gsub!(" EP", "")

    # Chck if artist and album combo is in in DB if not then store in DB and add to playlist
    if Album.first(:artist => "#{artist}", :album => "#{album}").nil? then
      id = store_album(artist, album, post_time)
      add_album(id)
    end
  end
end

# Check our unavailable albums for availability
puts "Checking if our unavailable albums have become available..."
unavail = repository(:default).adapter.select("select id from albums where can_stream = 'f' " )
unavail.each do |u|
  add_album(u)
end

u_tally = Album.count(:canStream => false)
puts "There are currently #{u_tally} albums still unavailable on Rdio"
  
