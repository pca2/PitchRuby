require 'rss'
require 'open-uri'

#Grab info from RSS feed
artists = []
albums = []

url = 'http://feeds2.feedburner.com/PitchforkBestNewAlbums'
open(url) do |rss|
  feed = RSS::Parser.parse(rss)
#Iterate through items, parse for artists and save to array
  feed.items.each do |item|
    artists.push(item.title[/^(?:(?!:).)*/].strip.to_s)
  end
#Iterate through items, parse for album and save to array
   feed.items.each do |item|
    albums.push(item.title[/(?:(?!:).)*$/].strip.to_s)
  end
end
#Combine two arrays into hash
listing = Hash[*artists.zip(albums).flatten]