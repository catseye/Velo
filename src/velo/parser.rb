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
    if (['EOL', 'EOF'].include? @scanner.type or [')', ','].include? @scanner.text)
      return nil
    end
    receiver = base  # could be Expr, StringLit, Arg
    if (['EOL', 'EOF'].include? @scanner.type or [')', ','].include? @scanner.text)
      return MethodCall.new(receiver, [])
    end
    while @scanner.consume '.'
      @scanner.consume_type 'EOL'
      debug "parsing .ident"
      ident = @scanner.text
      @scanner.scan
      receiver = Lookup.new(MethodCall.new(receiver, []), ident)
    end
    if @scanner.consume '='
      # this is an assignment, so we must resolve the reciever chain
      # as follows: a.b.c = foo becomes
      # lookup(a, b).set(c, foo)
      debug "unlookuping"
      ident = nil
      if receiver.is_a? Lookup
        ident = receiver.ident
        receiver = receiver.receiver
      else
        raise VeloSyntaxError, "assignment requires lvalue, but we have '#{@receiver}'"
      end
      debug "parsing assignment"
      @scanner.consume_type 'EOL'
      e = expr
      return Assignment.new(receiver, ident, e)
    elsif @scanner.type == 'EOF' or @scanner.type == 'EOL'
      # this is a plain value, so we must resolve the reciever chain
      # as follows: a.b.c becomes
      # lookup(lookup(a, b), c)
      debug "not a method call"
      return MethodCall.new(receiver, [])
    else
      # this is a method call, so we must resolve the reciever chain
      # as follows: a.b.c args becomes
      # methodcall(lookup(lookup(a, b), c), args)
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
