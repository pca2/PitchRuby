PitchRuby
=========

A Ruby script for parsing Pitchfork's best new albums RSS feed and adding songs
to an Rdio playlist.

Originally inspired by bawish's [Rdiofork](https://github.com/bawish/Rdiofork).

## Data structures

Since this was in part an excuse for me to learn redis, I tried to plan out
storing data based not only on what information I want to keep, but on how I
wanted to query it later.

1. Key => value to keep track of unique ids for each album: `albums:nextID`
  * We can get the next available ID with `redis.incr('albums:nextID')`
  * Example: `albums:nextID = 1`
2. Most importantly, I'm storing a redis hash of albums: `albums:#{id}` where id is from `albums:nextID`
  * We want to store the id, the artist, and the album title
  * Example: `albums:1 = { "id" => 1, "artist" => "Purity Ring", "title" =>
    "Shrines" }`

## Storage based on queries

### What was the most recently parsed RSS post?
This is just a simple key => value which stores the unix timestamp of the latest
post as the key `albums:latest_post`.
  * Example: `albums:latest_post = 1361822312`

### Do we already have an entry for this artist + album?
Redis key => value, where the key is `albums:artist:title` and the value is
the id of the album in the `albums:id` hash
  * Example: `albums:Purity Ring:Shrines = 1`

### Is this album available for streaming on rdio?
Redis "set" of unavailable albums: `albums:unavailable`
  * Example: `albums:unavailable = [ 1, 4, 8 ]`

