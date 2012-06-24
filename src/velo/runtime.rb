require 'velo/debug'

require 'velo/parser'
require 'velo/ast'

debug "loading runtime"

class VeloMethod
  def run obj, args
    # subclass must implement something more intelligent than this plz
    puts "arrrgghhh!"
  end
end

class FooMethod < VeloMethod
  def run obj, args
    puts "foo method called on #{obj} with args #{args}!"
  end
end

class VeloObject
  def initialize title
    @title = title
    @parents = []
    @methods = {}
    @attrs = {}
  end

  def to_s
    "#{@title}(#{@parents},#{@methods},#{@attrs})"
  end

  # let this object delegate to another object
  def extend obj
    @parents.unshift obj
  end

  def set_method ident, method
    @methods[ident] = method
  end

  def set_attr ident, obj
    @attrs[ident] = obj
  end

  # look up an identifier on this object, or any of its delegates
  def lookup ident
    if @methods.has_key? ident
      @methods[ident]
    elsif @attrs.has_key? ident
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

  def call_method ident, args
    method = lookup ident
    method.run self, args
  end
end

if $0 == __FILE__
  $debug = true
  # A toy objectbase

  velo_Object = VeloObject.new 'Object'
  velo_Object.set_method 'foo', FooMethod.new

  velo_String = VeloObject.new 'String'
  velo_String.extend velo_Object

  velo_String.call_method 'foo', [1,2,3]
end
