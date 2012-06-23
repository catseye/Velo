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
      return nil
    elsif @scanner.consume "("
      debug "parsing parens"
      e = expr
      @scanner.expect ")"
      # [Rest]
      return e
    elsif @scanner.type == 'strlit'
      debug "parsing strlit"
      s = @scanner.text
      @scanner.scan
      # [Rest]
      return StringLiteral.new(s)
    elsif @scanner.type == 'ident'
      debug "parsing ident"
      ident = @scanner.text
      @scanner.scan
      if @scanner.consume "="
        debug "parsing assignment"
        return Assignment.new(ident, expr)
      end
      # parse arguments -- should be in Rest
      if @scanner.consume ";"
        # no arguments
      else
        args = []
        e = expr
        args.push(e) unless e.nil?
        while @scanner.consume ","
          e = expr
          args.push(e) unless e.nil?
        end
        return MethodCall.new(ident, args)
      end
    else
      raise VeloSyntaxError, "unexpected '#{@scanner.text}'"
    end
  end
end
