#!/usr/bin/env ruby

# This is mostly a stub that always fails for now, so that we can at least
# run the tests defined in the README.

# (Part of me is also thinking it's a bad idea to try to implement Velo
# in Ruby, but for now, why not.)

class VeloSyntaxError < StandardError  
end

class Tokenizer
  def initialize s
    @string = s
    @text = nil
    @type = nil
    scan_impl
  end

  def text
    return @text
  end

  def type
    return @type
  end

  def set_token(text, type)
    @text = text
    @type = type
  end

  def scan
    scan_impl
    return @text
  end

  def scan_impl
    m = /^\s+(.*?)$/.match @string
    @string = m[1] if not m.nil?

    if @string.empty?
      set_token(nil, nil)
      return
    end

    # check for any single character tokens
    m = /^([(),.;=])(.*?)$/.match @string
    if m
      @string = m[2]
      set_token(m[1], 'seperator')
      return
    end

    # check for strings of "word" characters
    m = /^(\w+)(.*?)$/.match @string
    if m
      @string = m[2]
      set_token(m[1], 'ident')
      return
    end

    # literal strings
    if @string[0] == '{'
      index = 1
      level = 1
      while level > 0
        if @string[index] == '{'
          level += 1
        elsif @string[index] == '}'
          level -= 1
        end
        index += 1
      end
      token = @string[1..index-2]
      @string = @string[index..@string.length-index]
      set_token(token, 'strlit')
      return
    end

    set_token(nil, nil)
  end

  def consume s
    if @text == s
      scan
      true
    else
      false
    end
  end

  def expect s
    if @text == s
      scan
    else
      raise VeloSyntaxError, "expected '#{s}', found '#{@text}'"
    end
  end
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

############# AST ############

class AST
end

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

############ Main ############

ARGV.each do |filename|
end

$stderr.puts "I fail"
exit false
