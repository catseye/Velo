require 'velo/scanner.rb'
require 'velo/ast.rb'

puts "loading parser"

class VeloSyntaxError < StandardError  
end

# Grammar:

# Velo ::= {Expr}.
# Expr ::= Name "=" Expr
#        | Expr {"." Name} (";" | Expr {"," Expr})
#        | Name
#        | "(" Expr ")"
#        | StringLiteral
#        .

# Refactored to be LL(1):

# Velo ::= {Expr}.
# Expr ::= Name [Assn | Rest]
#        | "(" Expr ")" [Rest]
#        | StringLiteral [Rest]
#        .
# Assn ::= "=" Expr.
# Rest ::= {"." Name} (";" | Expr {"," Expr})

class Parser
  def initialize s
    @tokenizer = Tokenizer.new(s)
  end

# Expr ::= Name [Rest]
#        | StringLiteral [Rest]
#        .
# Rest ::= {"." Name} (";" | Expr {"," Expr})

  def script
    exprs = []
    e = expr
    while not e.nil?
      exprs.push(e)
      e = expr
    end
    Script.new(exprs)
  end

  def expr
    if @tokenizer.consume "("
      e = expr
      @tokenizer.expect ")"
      # [Rest]
      return e
    elsif @tokenizer.type == 'strlit'
      s = @tokenizer.text
      @tokenizer.scan
      # [Rest]
      return StringLiteral(s)
    elsif @tokenizer.type == 'ident'
      ident = @tokenizer.text
      @tokenizer.scan
      if @tokenizer.consume "="
        return Assignment(ident, expr)
      end
    else
      raise VeloSyntaxError, "unexpected '#{@tokenizer.text}'"
    end
  end
end
