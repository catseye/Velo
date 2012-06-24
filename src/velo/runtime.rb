require 'velo/debug'

require 'velo/exceptions'
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
    "VeloObject('#{@title}')"
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
  def lookup ident
    debug "lookup #{ident} on #{self}"
    result = lookup_impl ident, []
    debug "lookup result: #{result}"
    if result.nil?
      raise VeloAttributeNotFound, "could not locate '#{ident}' on #{self}"
    end
    result
  end

  # look up an identifier on this object, or any of its delegates
  def lookup_impl ident, trail
    debug "lookup_impl #{ident} on #{self}"
    if trail.include? self
      debug "we've already seen this object, stopping search"
      return nil
    end
    trail.push self
    if @attrs.has_key? ident
      debug "found here (#{self}), it's #{@attrs[ident]}"
      @attrs[ident]
    else
      x = nil
      for parent in @parents
        x = parent.lookup_impl ident, trail
        break if not x.nil?
      end
      x
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
$Object.set 'self', VeloMethod.new('self', proc { |obj, args|
  raise VeloMethodNotImplemented
})
$Object.set 'new', VeloMethod.new('new', proc { |obj, args|
  raise VeloMethodNotImplemented
})

$String = VeloObject.new 'String'
$String.set 'concat', VeloMethod.new('concat', proc { |obj, args|
  debug "concat #{obj} #{args[0]}"
  obj.contents = obj.contents + args[0].contents
  # XXX should this create a new object, maybe?
  obj
})
$String.set 'class', VeloMethod.new('class', proc { |obj, args|
  raise VeloMethodNotImplemented
})
$String.set 'method', VeloMethod.new('method', proc { |obj, args|
  raise VeloMethodNotImplemented
})
$String.set 'if', VeloMethod.new('if', proc { |obj, args|
  raise VeloMethodNotImplemented
})

$IO = VeloObject.new 'IO'
$IO.set 'print', VeloMethod.new('print', proc { |obj, args|
  puts args[0].contents
})

$Object.set 'Object', $Object
$Object.set 'String', $String
$Object.set 'IO', $IO

### ... ###

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
