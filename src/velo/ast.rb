require 'velo/debug'

require 'velo/runtime'

debug "loading ast"

class AST
  def eval obj, args
    # abstract
  end
end

class Script < AST
  def initialize exprs
    @exprs = exprs
  end

  def eval obj, args
    debug "eval #{self} on #{obj} with #{args}"
    e = nil
    for expr in @exprs
      e = expr.eval obj, args
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
  def initialize object, field, expr
    @object = object
    @field = field
    @expr = expr
  end

  def eval obj, args
    debug "eval #{self} on #{obj} with #{args}"
    val = @expr.eval obj, args
    receiver = @object.eval obj, args
    if receiver.is_a? VeloMethod
      receiver = receiver.run obj, []
    end
    receiver.set @field, val
    val
  end

  def to_s
    "Assignment(#{@object},#{@field},#{@expr})"
  end
end

# This is great... we have an AST node that doesn't correspond to any part
# of the concrete syntax.  (It corresponds to the 'implicit self'.)
class Self < AST
  def eval obj, args
    debug "eval #{self} on #{obj} with #{args}"
    obj
  end

  def find_receiver obj, args
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

  def find_receiver obj, args
    debug "find_receiver #{self}"
    @receiver.eval obj, args
  end

  def eval obj, args
    debug "eval #{self} on #{obj} with #{args}"
    receiver = @receiver.eval obj, args
    if receiver.is_a? VeloMethod
      receiver = receiver.run obj, []
    end
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

  def eval obj, args
    debug "eval #{self} on #{obj} with #{args}"
    new_args = []
    for expr in @exprs
      new_args.push(expr.eval obj, args)
    end
    method = @method_expr.eval obj, args
    debug "arguments evaluated, now calling #{@method_expr} -> #{method}"
    receiver = @method_expr.find_receiver obj, args
    if method.is_a? VeloMethod
      debug "running real method #{method} w/args #{args}, receiver=#{receiver}"
      method.run receiver, new_args
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

class Argument < AST
  def initialize num
    @num = num-1
  end

  def eval obj, args
    debug "eval #{self} on #{obj} with #{args}"
    args[@num]
  end

  def to_s
    "Argument(#{@num})"
  end
end

class StringLiteral < AST
  def initialize text
    @text = text
  end

  def eval obj, args
    debug "eval #{self} on #{obj} with #{args}"
    make_string_literal @text
  end

  def to_s
    "StringLiteral('#{@text}')"
  end
end
