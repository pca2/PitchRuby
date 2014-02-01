PitchRuby
=========

A Ruby script for parsing Pitchfork's best new albums RSS feed and adding songs
to an Rdio playlist.

Originally inspired by bawish's [Rdiofork](https://github.com/bawish/Rdiofork).

This version of the script stores the parsed album data in a sqlite file. It uses [Datamapper](https://datamapper.org) as the ORM. Earlier versions relied on redis but I decided sqlite was better suited for our needs. 

New albums are added to the top of the playlist. Albums that are not available are stored in the DB and checked for availability each time the script is run. Currently there is no way to ensure that only new albums from the current year are added to the playlist. That feature may be added in future versions, if we ever get around to it.

The rdio.rb and om.rb files are manually included here because we ran into some issues with the [official rdio Ruby wrapper](https://github.com/rdio/rdio-simple/tree/master/ruby) versus spudtrooper's [3rd-prty solution](http://rubygems.org/gems/rdio).  

