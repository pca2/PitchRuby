#!/usr/bin/env ruby
#quick script to obtain permenant Rdio token

require './rdio'
require './credentials_and_settings'
# create an instance of the Rdio object with our consumer credentials
rdio = Rdio.new([RDIO_CONSUMER_KEY, RDIO_CONSUMER_SECRET])

# authenticate against the Rdio service
url = rdio.begin_authentication('oob')
puts 'Go to: ' + url
print 'Then enter the code: '
verifier = gets.strip
rdio.complete_authentication(verifier)

puts "RDIO_TOKEN: " + rdio.token[0]
puts "RDIO_TOKEN_SECRET: " + rdio.token[1]
