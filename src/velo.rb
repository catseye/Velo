#!/usr/bin/env ruby

# This is mostly a stub that always fails for now, so that we can at least
# run the tests defined in the README.

# (Part of me is also thinking it's a bad idea to try to implement Velo
# in Ruby, but for now, why not.)

require 'velo/debug.rb'
$debug = false
require 'velo/parser.rb'

############ Main ############

ARGV.each do |arg|
  if arg == '--debug'
    $debug = true
    next
  end
  File.open(arg, 'r') do |f|
    text = ''
    while line = f.gets
      text += line
    end
    p = Parser.new(text)
    s = p.script
    puts s
  end
end
