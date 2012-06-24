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
    e = expr.eval obj
    obj.set ident, e
    e
  end

  def to_s
    "Assignment(#{@ident}=#{@expr})"
  end
end

class Lookup < AST
  def initialize receiver, ident
    @receiver = receiver
    @ident = ident
  end

  def eval obj
    receiver = @receiver
    if receiver == 'self'
      receiver = obj
    end
    receiver.call @ident, []
  end

  def to_s
    "Lookup(#{@receiver}.#{@ident})"
  end
end

class MethodCall < AST
  def initialize ident, exprs
    @ident = ident
    @exprs = exprs
  end

  def eval obj
    args = []
    for expr in @exprs
      args.push(expr.eval obj)
    end
    obj.call @ident, args
  end

  def to_s
    text = "MethodCall(#{@ident},"
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
    mkstring @text
  end

  def to_s
    "StringLiteral(#{@text})"
  end
end
