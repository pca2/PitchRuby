PitchRuby
=========

A Ruby script for parsing Pitchfork's best new albums RSS feed and adding songs to an Rdio playlist.

Originally inspired by bawish's [Rdiofork](https://github.com/bawish/Rdiofork).

This script is a work in progress and doesn't actually work yet, so stay tuned.

## To Do

Biggest item right now is working with Rdio api. There's the official [Rdio Ruby client](https://github.com/rdio/rdio-simple/tree/master/ruby) but it only works with Ruby 1.8. There's [rdio_api](https://github.com/anilv/rdio_api) but it doesn't include an oauth flow. I'm new to managing oauth (and everything else) so I'm still trying to figure that out.

## Planned  Workflow

1. Grab items RSS feed.

2. Parse artists and albums into separate arrays, then combine arrays into one hash.

At the moment that's as far as I've gotten.

3. query Rdio for each artist in hash, a list of albums will be returned.

4. Iterate through album titles, checking for albums in hash.

4. If album matches one in the hash, get track listing.
 
5. Add tracks to top of playlist.

6. Iterate through hash and check if albums are available. If they become available add them to playlist, if they cease to be available remove them.
