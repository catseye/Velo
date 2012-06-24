require 'velo/debug.rb'

require 'velo/scanner.rb'
require 'velo/ast.rb'

debug "loading parser"

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
    @scanner = Scanner.new(s)
  end

# Expr ::= Name [Rest]
#        | StringLiteral [Rest]
#        .
# Rest ::= {"." Name} (";" | Expr {"," Expr})

  def script
    debug "parsing Script production"
    exprs = []
    e = expr
    while not e.nil?
      exprs.push(e)
      e = expr
    end
    Script.new(exprs)
  end

  def expr
    debug "parsing Expr production"
    if @scanner.type == 'EOF'
      nil
    elsif @scanner.consume "("
      debug "parsing parens"
      e = expr
      @scanner.expect ")"
      rest e
    elsif @scanner.type == 'strlit'
      debug "parsing strlit"
      s = @scanner.text
      @scanner.scan
      rest StringLiteral.new(s)
    elsif @scanner.type == 'ident'
      debug "parsing ident"
      ident = @scanner.text
      @scanner.scan
      if @scanner.consume "="
        debug "parsing assignment"
        return Assignment.new(ident, expr)
      end
      rest Lookup.new('self', ident)
    else
      raise VeloSyntaxError, "unexpected '#{@scanner.text}'"
    end
  end

  def rest receiver
    debug "parsing Rest (of Expr) production"
    if @scanner.consume "."
      debug "parsing lookup"
      ident = @scanner.text
      @scanner.scan
      rest Lookup.new(receiver, ident)
    elsif @scanner.consume ";"
      # no arguments
      receiver
    else
      args = []
      e = expr
      args.push(e) unless e.nil?
      while @scanner.consume ","
        e = expr
        args.push(e) unless e.nil?
      end
      MethodCall.new(receiver, args)
    end
  end
end
