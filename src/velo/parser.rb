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

# Velo ::= {Expr EOL}.
# Expr ::= Name [Assn | Rest]
#        | "(" [EOL] Expr ")" [Rest]
#        | StringLiteral [Rest]
#        .
# Assn ::= "=" [EOL] Expr
# Rest ::= "." [EOL] Rest
#        | Expr {"," [EOL] Expr}

class Parser
  def initialize s
    @scanner = Scanner.new(s)
  end

  def script
    debug "parsing Script production"
    exprs = []
    e = expr
    while not e.nil?
      @scanner.expect_type ["EOL", "EOF"]
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
      @scanner.consume_type 'EOL'
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
        @scanner.consume_type 'EOL'
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
      @scanner.consume_type 'EOL'
      ident = @scanner.text
      @scanner.scan
      rest Lookup.new(receiver, ident)
    elsif ['EOL', 'EOF'].include? @scanner.type
      receiver
    elsif [')', ','].include? @scanner.text 
      receiver
    else
      args = []
      e = expr
      args.push(e) unless e.nil?
      while @scanner.consume ","
        @scanner.consume_type 'EOL'
        e = expr
        args.push(e) unless e.nil?
      end
      MethodCall.new(receiver, args)
    end
  end
end

if $0 == __FILE__
  #$debug = true
  p = Parser.new(ARGV[0])
  s = p.script
  puts s

  if $debug
    s1 = Parser.new('m a, m b, c').script
    s2 = Parser.new('m a, (m b, c)').script
    s3 = Parser.new('m a, (m b), c').script
    puts s1
    puts s2
    puts s3
  end
end
