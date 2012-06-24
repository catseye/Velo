require 'velo/debug'

require 'velo/parser'
require 'velo/ast'

debug "loading runtime"

class VeloObject
  def initialize
    @parents = []
    @methods = {}
    @attrs = {}
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
        break if not obj.nil?
      end
      x
    end
  end
end
