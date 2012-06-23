class AST
end

puts "loading ast"

class Script < AST
  def initialize exprs
    @exprs = exprs
  end
end

class Assignment < AST
  def initialize ident, expr
    @ident = ident
    @expr = expr
  end
end

class StringLiteral < AST
  def initialize text
    @text = text
  end
end
