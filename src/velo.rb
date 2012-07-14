#!/usr/bin/env ruby

require 'velo/debug'
$debug = false
require 'velo/parser'
require 'velo/runtime'

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
    o = VeloObject.new 'main-script'
    s.eval o, []   # XXX could pass command-line arguments here...
  end
end
