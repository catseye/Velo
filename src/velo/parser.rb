require 'velo/debug'

require 'velo/exceptions'
require 'velo/scanner'
require 'velo/ast'

debug "loading parser"

# Grammar:

# Velo ::= {Expr}.
# Expr ::= Name "=" Expr
#        | Expr {"." Name} (";" | Expr {"," Expr})
#        | Name
#        | "(" Expr ")"
#        | StringLiteral
#        | ArgumentRef
#        .

# Refactored to be LL(1):

# Velo ::= {[EOL] Expr EOL}.
# Expr ::= Name [Assn | Rest]
#        | "(" [EOL] Expr ")" [Rest]
#        | StringLiteral [Rest]
#        | ArgumentRef
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
    @scanner.consume_type "EOL"
    e = expr
    while not e.nil?
      @scanner.expect_types ["EOL", "EOF"]
      exprs.push(e)
      @scanner.consume_type "EOL"
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
      rest e, false
    elsif @scanner.type == 'strlit'
      debug "parsing strlit"
      s = @scanner.text
      @scanner.scan
      rest StringLiteral.new(s), false
    elsif @scanner.type == 'arg'
      debug "parsing arg"
      num = @scanner.text.to_i
      @scanner.scan
      rest Argument.new(num), false
    elsif @scanner.type == 'ident'
      debug "parsing ident"
      ident = @scanner.text
      @scanner.scan
      if @scanner.consume "="
        debug "parsing assignment"
        @scanner.consume_type 'EOL'
        return Assignment.new(ident, expr)
      end
      # we now parse the rest of the expression.  If there is no rest of
      # the expression, though, we want to make sure this is a method call.
      rest Lookup.new(Self.new, ident), true
    else
      raise VeloSyntaxError, "unexpected '#{@scanner.text}'"
    end
  end

  def rest receiver, is_call
    debug "parsing Rest (of Expr) production"
    if @scanner.consume "."
      debug "parsing lookup"
      @scanner.consume_type 'EOL'
      ident = @scanner.text
      @scanner.scan
      rest Lookup.new(receiver, ident), true
    elsif (['EOL', 'EOF'].include? @scanner.type or [')', ','].include? @scanner.text)
      if is_call
        MethodCall.new(receiver, [])
      else
        receiver
      end
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
