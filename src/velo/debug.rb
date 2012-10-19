$debug = false

def debug s
  if $debug
    puts "--> #{s}"
  end
end
