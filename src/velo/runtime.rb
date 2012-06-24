require 'velo/debug'

require 'velo/parser'
require 'velo/ast'

debug "loading runtime"

# the built-in objects, for convenience of other sources
$Object = nil
$String = nil
$IO = nil

# title is for debugging only.  methods themselves do not have names.
class VeloMethod
  def initialize title, fun
    @title = title
    @fun = fun
  end

  def run obj, args
    @fun.call obj, args
  end
  
  def to_s
    "VeloMethod(#{@title})"
  end
end

# parents will be [] for Object, [Object] for all other objects
class VeloObject
  def initialize title
    @title = title
    @parents = []
    @parents.push $Object if not $Object.nil?
    @attrs = {}
    @contents = nil
  end

  def to_s
    "#{@title}(#{@parents},#{@attrs})"
  end

  def set ident, method
    @attrs[ident] = method
  end

  # let this object delegate to another object
  def extend obj
    debug "extending #{self} w/#{obj}"
    @parents.unshift obj
  end

  # look up an identifier on this object, or any of its delegates
  def lookup ident, trail
    debug "lookup #{ident} on #{self}"
    if trail.include? self
      debug "we've already seen this object, stopping search"
      nil
    end
    trail.push self
    if @attrs.has_key? ident
      debug "found here"
      @attrs[ident]
    else
      x = nil
      for parent in @parents
        x = parent.lookup ident, trail
        break if not x.nil?
      end
      x
    end
  end

  def call ident, args
    if not ident.is_a? String
      raise "identifier being called is not a string! '#{ident}'"
    end
    attr = lookup ident, []
    debug "calling #{ident} (#{attr}) on #{self}"
    if attr.is_a? VeloMethod
      attr.run self, args
    else
      attr
    end
  end

  def contents
    @contents
  end
  
  def contents= c
    @contents = c
  end
end

### establish the objectbase ###

$Object = VeloObject.new 'Object'

$Object.set 'extend', VeloMethod.new('extend', proc { |obj, args|
  obj.extend args[0]
})

$String = VeloObject.new 'String'

$IO = VeloObject.new 'IO'

$IO.set 'print', VeloMethod.new('print', proc { |obj, args|
  puts args[0]
})

$Object.set 'Object', $Object
$Object.set 'String', $String
$Object.set 'IO', $IO

### ... ###

def mkstring s
  o = VeloObject.new 'String literal'
  o.extend $String
  o.contents = s
end

if $0 == __FILE__
  $debug = true
  $Object.set 'foo', VeloMethod.new('foo', proc { |obj, args|
    puts "foo method called on #{obj} with args #{args}!"
  })
  $String.set 'bar', VeloMethod.new('bar', proc { |obj, args|
    puts "bar method called on #{obj} with args #{args}!"
  })

  velo_Shimmy = VeloObject.new 'Shimmy'
  velo_Shimmy.call 'extend', [$String]
  velo_Shimmy.call 'bar', [1,2,3]
end
