begin
  #require_relative 'libGoo/hackex/typhoeus'
rescue LoadError
  puts "Typheous not available: #{$!}"
end
require_relative 'libGoo/hackex/net/std' unless defined?(HackEx::Network)

require_relative 'libGoo/hackex/error'
require_relative 'libGoo/hackex/helper'
require_relative 'libGoo/hackex/request'
require_relative 'libGoo/hackex/action'
require_relative 'libGoo/hackex/hackex'
