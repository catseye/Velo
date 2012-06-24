require 'velo/debug'

require 'velo/runtime'

debug "loading ast"

class AST
  def eval obj
    # abstract
  end
end

class Script < AST
  def initialize exprs
    @exprs = exprs
  end

  def eval obj
    debug "eval #{self}"
    e = nil
    for expr in @exprs
      e = expr.eval obj
    end
    e
  end

  def to_s
    text = "Script(\n"
    for e in @exprs
      text += "  " + e.to_s + ",\n"
    end
    text + ")"
  end
end

class Assignment < AST
  def initialize ident, expr
    @ident = ident
    @expr = expr
  end

  def eval obj
    debug "eval #{self}"
    e = @expr.eval obj
    obj.set @ident, e
    e
  end

  def to_s
    "Assignment(#{@ident},#{@expr})"
  end
end

# This is great... we have an AST node that doesn't correspond to any part
# of the concrete syntax.  (It corresponds to the 'implicit self'.)
class Self < AST
  def eval obj
    obj
  end

  def find_receiver obj
    obj
  end

  def to_s
    "Self()"
  end
end

class Lookup < AST
  def initialize receiver, ident
    @receiver = receiver
    @ident = ident
  end

  def receiver
    @receiver
  end

  def ident
    @ident
  end

  def find_receiver obj
    debug "find_receiver #{self}"
    @receiver.eval obj
  end

  def eval obj
    debug "eval #{self}"
    receiver = @receiver.eval obj
    receiver.lookup @ident
  end

  def to_s
    "Lookup(#{@receiver},'#{@ident}')"
  end
end

class MethodCall < AST
  def initialize method_expr, exprs
    @method_expr = method_expr
    @exprs = exprs
  end

  def eval obj
    debug "eval #{self}"
    args = []
    for expr in @exprs
      args.push(expr.eval obj)
    end
    method = @method_expr.eval obj
    debug "arguments evaluated, now calling #{@method_expr} -> #{method}"
    receiver = @method_expr.find_receiver obj
    if method.is_a? VeloMethod
      debug "running real method #{method} w/args #{args}, receiver=#{receiver}"
      method.run receiver, args
    else
      debug "just returning non-method (#{method}) on call, receiver=#{receiver}"
      method
    end
  end

  def to_s
    text = "MethodCall(#{@method_expr},"
    for e in @exprs
      text += e.to_s + ","
    end
    text + ")"
  end
end

class StringLiteral < AST
  def initialize text
    @text = text
  end

  def eval obj
    debug "eval #{self}"
    make_string_literal @text
  end

  def to_s
    "StringLiteral('#{@text}')"
  end
end
