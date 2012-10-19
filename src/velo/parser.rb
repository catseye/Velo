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
# Expr ::= Base {"." [EOL] Name} ["=" [EOL] Expr | Expr {"," [EOL] Expr}].
# Base ::= Name
#        | ArgumentRef
#        | StringLiteral
#        | "(" [EOL] Expr ")"
#        .

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
      return nil
    end
    receiver = base  # could be Expr, StringLit, Arg, Ident
    if @scanner.type == 'EOF'
      return receiver
    end
    while @scanner.consume '.'
      @scanner.consume_type 'EOL'
      debug "parsing .ident"
      ident = @scanner.text
      @scanner.scan
      receiver = Lookup.new(receiver, ident)
    end
    if @scanner.consume '='
      debug "parsing assignment"
      @scanner.consume_type 'EOL'
      e = expr
      # assign to last thing in lookup chain... urgh.  maybe turn into method call?
      return Assignment.new(ident, e)
    elsif @scanner.type == 'EOF' or @scanner.type == 'EOL'
      debug "not a method call"
      return receiver
    else
      debug "parsing method call args"
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

  def base
    debug "parsing Base production"
    if @scanner.consume "("
      debug "parsing parens"
      @scanner.consume_type 'EOL'
      e = expr
      @scanner.expect ")"
      return e
    elsif @scanner.type == 'strlit'
      debug "parsing strlit"
      s = @scanner.text
      @scanner.scan
      return StringLiteral.new(s)
    elsif @scanner.type == 'arg'
      debug "parsing arg"
      num = @scanner.text.to_i
      @scanner.scan
      return Argument.new(num)
    elsif @scanner.type == 'ident'
      debug "parsing ident"
      ident = @scanner.text
      @scanner.scan
      return Lookup.new(Self.new, ident)
    else
      raise VeloSyntaxError, "unexpected '#{@scanner.text}'"
    end
  end

  # no longer used -- goofy.
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
