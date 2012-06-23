#!/usr/bin/env ruby

# This is mostly a stub that always fails for now, so that we can at least
# run the tests defined in the README.

# (Part of me is also thinking it's a bad idea to try to implement Velo
# in Ruby, but for now, why not.)

require 'velo/debug.rb'
$debug = true
require 'velo/parser.rb'

############ Main ############

ARGV.each do |filename|
  File.open(filename, 'r') do |f|
    text = ''
    while line = f.gets
      text += line
    end
    p = Parser.new(text)
    s = p.script
    debug s
  end
end

$stderr.puts "I fail"
exit false
