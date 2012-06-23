require 'velo/debug.rb'

debug "loading ast"

class AST
end

class Script < AST
  def initialize exprs
    @exprs = exprs
  end
  
  def to_s
    text = "Script("
    for e in @exprs
      text += e.to_s + ","
    end
    text + ")"
  end
end

class Assignment < AST
  def initialize ident, expr
    @ident = ident
    @expr = expr
  end

  def to_s
    "Assignment(#{@ident}=#{@expr})"
  end
end

class MethodCall < AST
  def initialize ident, exprs
    @ident = ident
    @exprs = exprs
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

  def to_s
    "StringLiteral(#{@text})"
  end
end
