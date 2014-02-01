PitchRuby
=========

A Ruby script for parsing Pitchfork's best new albums RSS feed and adding songs
to an Rdio playlist.

Originally inspired by bawish's [Rdiofork](https://github.com/bawish/Rdiofork).

This version of the script stores the parsed album data in a sqlite file. It uses [Datamapper](https://datamapper.org) as the ORM. [Earlier versions](https://github.com/pca2/PitchRuby/tree/8f079bcc1c1ab2324fa4923c6ca28a70af5e36bb) relied on redis but I think sqlite is better suited for our needs at the moment. 

New albums are added to the top of the playlist. Albums that are not available are stored in the DB and checked for availability each time the script is run. Currently there is no way to ensure that only new albums from the current year are added to the playlist. That feature may be added in future versions, if we ever get around to it.

The rdio.rb and om.rb files are manually included here because we ran into some issues with the [official rdio Ruby wrapper](https://github.com/rdio/rdio-simple/tree/master/ruby) versus spudtrooper's [3rd-prty solution](http://rubygems.org/gems/rdio).  

The rdio playlist for 2014 is available [here](http://www.rdio.com/people/carleton/playlists/8006024/Pitchfork_Best_New_Albums_2014/).
