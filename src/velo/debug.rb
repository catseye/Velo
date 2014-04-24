$debug = false
$debug_scan = false

def debug s
  if $debug
    puts "--> #{s}"
  end
end
