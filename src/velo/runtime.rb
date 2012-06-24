require 'velo/debug'

require 'velo/parser'
require 'velo/ast'

debug "loading runtime"

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

# title is for debugging only.  objects themselves do not have names.
# parents will be [] for Object, [Object] for all other objects
class VeloObject
  def initialize title, parents
    @title = title
    @parents = parents
    @attrs = {}
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
  def lookup ident
    debug "lookup #{ident} on #{self}"
    if @attrs.has_key? ident
      debug "found here"
      @attrs[ident]
    else
      x = nil
      for parent in @parents
        x = parent.lookup ident
        break if not x.nil?
      end
      x
    end
  end

  def call ident, args
    attr = lookup ident
    debug "calling #{ident} (#{attr}) on #{self}"
    if attr.is_a? VeloMethod
      attr.run self, args
    else
      attr
    end
  end
end

if $0 == __FILE__
  #$debug = true
  # A toy objectbase

  velo_Object = VeloObject.new 'Object', []

  velo_Object.set 'extend', VeloMethod.new('extend', proc { |obj, args|
    obj.extend args[0]
  })

  velo_Object.set 'foo', VeloMethod.new('foo', proc { |obj, args|
    puts "foo method called on #{obj} with args #{args}!"
  })

  velo_String = VeloObject.new 'String', [velo_Object]
  velo_String.set 'bar', VeloMethod.new('bar', proc { |obj, args|
    puts "bar method called on #{obj} with args #{args}!"
  })

  velo_Shimmy = VeloObject.new 'Shimmy', [velo_Object]
  velo_Shimmy.call 'extend', [velo_String]
  velo_Shimmy.call 'bar', [1,2,3]
end
