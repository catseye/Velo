#!/usr/bin/env lua

--[[ ========== DEBUG ========= ]]--

local debug = function(s)
    print("--> " .. s)
end

--[[ ========== EXCEPTIONS ========= ]]--

function raise_VeloSyntaxError(s)
    error("VeloSyntaxError: " .. s)
end

function raise_VeloAttributeNotFound(s)
    error("VeloAttributeNotFound: " .. s)
end

function raise_VeloMethodNotImplemented(s)
    error("VeloMethodNotImplemented: " .. s)
end

--[[ =========== AST ========== ]]--

--[[
class AST
  def eval obj, args
    # abstract
  end
end
]]--

Script = {}
Script.new = function(exprs)
    methods = {}

    methods.eval = function(obj, args)
        debug "eval #{self} on #{obj} with #{args}"
        local e = nil
        for i,expr in ipairs(exprs) do
            e = expr:eval(obj, args)
        end
        return e
    end

    methods.to_s = function()
        local text = "Script(\n"
        for i,expr in ipairs(exprs) do
           text = text .. "  " .. expr.to_s() .. ",\n"
        end
        return text .. ")"
    end
    
    return methods
end

Assignment = {}
Assignment.new = function(object, field, expr)
    methods = {}

    methods.eval = function(obj, args)
        debug "eval #{self} on #{obj} with #{args}"
        local val = expr:eval(obj, args)
        local receiver = object:eval(obj, args)
        debug "setting #{@field} on #{receiver}"
        receiver:set(field, val)
        return val
    end

    methods.to_s = function()
        return "Assignment(" .. object.to_s() .. "," ..
                                field .. "," ..
                                expr.to_s() .. ")"
    end
    
    return methods
end

--# This is great... we have an AST node that doesn't correspond to any part
--# of the concrete syntax.  (It corresponds to the 'implicit self'.)

Self = {}
Self.new = function()
    methods = {}

    methods.eval = function(obj, args)
        debug "eval #{self} on #{obj} with #{args}"
        return obj
    end

    methods.to_s = function()
        return "Self()"
    end
    
    return methods
end

Lookup = {}
Lookup.new = function(_receiver, _ident)
    methods = {}

    methods.receiver = function()
        return _receiver
    end

    methods.ident = function()
        return _ident
    end

    methods.eval = function(obj, args)
        debug "eval #{self} on #{obj} with #{args}"
        local receiver = _receiver:eval(obj, args)
        return receiver:lookup(_ident)
    end

    methods.to_s = function()
        return "Lookup(" .. _receiver.to_s() .. "," .. _ident .. ")"
    end
    
    return methods
end

MethodCall = {}
MethodCall.new = function(method_expr, exprs)
    methods = {}

    methods.eval = function(obj, args)
        debug "eval #{self} on #{obj} with #{args}"
        local new_args = {}
        for i,expr in ipairs(exprs) do
            new_args.push(expr:eval(obj, args))
        end
        local method = method_expr:eval(obj, args)
        debug "arguments evaluated, now calling #{@method_expr} -> #{method}"
        -- OOOH
        if method.is_a_VeloMethod ~= nil then
            --# xxx show receiver (method's bound object) in debug
            debug "running real method #{method} w/args #{args}"
            return method:run(new_args)
        else
            debug "just returning non-method (#{method}) on call"
            return method
        end
    end

    methods.to_s = function()
        local text = "MethodCall(" .. method_expr.to_s() .. ","
        for i,expr in ipairs(exprs) do
            text = text .. expr.to_s() .. ","
        end
        return text .. ")"
    end
    
    return methods
end

Argument = {}
Argument.new = function(num)
    num = num - 1
    methods = {}

    methods.eval = function(obj, args)
        debug "eval #{self} on #{obj} with #{args}"
        return args[num]
    end

    methods.to_s = function()
        return "Argument(" .. num .. ")"
    end
    
    return methods
end

StringLiteral = {}
StringLiteral.new = function(text)
    methods = {}

    methods.eval = function(obj, args)
        debug "eval #{self} on #{obj} with #{args}"
        return make_string_literal(text)
    end

    methods.to_s = function()
        return "StringLiteral(" .. text .. ")"
    end
    
    return methods
end

-- SANITY TEST
local m = MethodCall.new(Self.new(), {Argument.new(1), StringLiteral.new("jonkers")})
local a = Assignment.new(m, "bar", Lookup.new(Self.new(), "foo"))
s = Script.new({a, Self.new()}); print(s:to_s())

--[[ ========== SCANNER ========= ]]--

Scanner = {}
Scanner.new = function(s)
    local string = s
    local _text = nil
    local _type = nil

    methods = {}

    methods.text = function() return _text end
    methods.type = function() return _type end

    methods.is_eof = function()
        return _type == "EOF"
    end

    methods.set_token = function(text, type)
        _text = text
        _type = type
        debug "set_token '#{@text}' (#{@type})"
        --#debug "string now '#{@string}'"
    end

    methods.scan = function()
        methods.scan_impl()
        debug("scanned " .. _text .. " (" .. _type .. ")")
        return _text
    end

    methods.scan_impl = function()
      --[[
        m = /\A[ \t]+/.match @string
        if not m.nil?
          @string = m.post_match
          #debug "consumed whitespace, string now '#{@string}'"
        end
        
        if @string.empty?
          set_token('EOF', 'EOF')
          return
        end
        
        m = /\A[\r\n;]+/.match @string
        if not m.nil?
          while not m.nil?
            @string = m.post_match
            m = /\A[ \t]*[\r\n;]+/.match @string
          end
          set_token('EOL', 'EOL')
          return
        end
        
        # check for any single character tokens
        m = /\A([(),.;=])/.match @string
        if m
          @string = m.post_match
          set_token(m[1], 'seperator')
          return
        end
        
        # check for arguments
        m = /\A\#(\d+)/.match @string
        if m
          @string = m.post_match
          set_token(m[1], 'arg')
          return
        end
        
        # check for strings of "word" characters
        m = /\A(\w+)/.match @string
        if m
          @string = m.post_match
          set_token(m[1], 'ident')
          return
        end
        
        # literal strings
        if @string[0] == ?{
          #debug "scanning strlit '#{@string}'"
          index = 1
          level = 1
          while level > 0
            if @string[index] == ?{
              level += 1
            elsif @string[index] == ?}
              level -= 1
            end
            index += 1
            if index >= @string.length
              index = @string.length
              break
            end
          end
          token = @string[1..index-2]
          @string = @string[index..-1]
          set_token(token, 'strlit')
          return
        end
        ]]--
        debug "scanner couldn't scan '#{@string}'"

        methods.set_token('UNKNOWN', 'UNKNOWN')
    end
    
    methods.consume = function(s)
        if _text == s then
            methods.scan()
            return true
        else
            return false
        end
    end

    methods.consume_type = function(t)
        if _type == t then
            methods.scan()
            return true
        else
            return false
        end
    end

    methods.expect = function(s)
        if _text == s then
            methods.scan()
        else
            raise_VeloSyntaxError("expected '" .. s ..
                                  "', found '" .. _text .. "'")
        end
    end

    methods.expect_types = function(types)
        local good = false
        for i,type in ipairs(types) do
            if type == _type then
                good = true
                break
            end
        end
        if not good then
            raise_VeloSyntaxError("expected '#{t}', found '#{@text}' (#{@type})")
        end
    end

    debug("created scanner with string " .. string)
    -- AND WHOEVER CREATED THIS MUST CALL scan()

    return methods
end

x = Scanner.new("the quick brown fox etc")
x.scan()
while not x.is_eof() do
    print(x.text() .. ":" .. x.type())
    x.scan()
end

--[[ ========== PARSER ========== ]]--

--[[

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
]]--

--[[ ========== RUNTIME ========= ]]--

--# the built-in objects, for convenience of other sources
global_Object = nil
global_String = nil
global_IO = nil

--[[

# title is for debugging only.  methods themselves do not have names.
class VeloMethod
  def initialize title, fun
    @title = title
    @fun = fun
    @obj = nil
  end

  def bind_object obj
    @obj = obj
  end

  def run args
    @fun.call @obj, args
  end
  
  def to_s
    "VeloMethod(#{@title})"
  end
end

# parents will be [] for Object, [Object] for all other objects
class VeloObject
  def initialize title
    @title = title
    @parents = []
    @parents.push $Object if not $Object.nil?
    @attrs = {}
    @contents = nil
  end

  def to_s
    "VeloObject('#{@title}')"
  end

  def set ident, obj
    @attrs[ident] = obj
    debug "set #{ident} to #{obj} on #{self}"
  end

  # let this object delegate to another object
  def velo_extend obj
    debug "extending #{self} w/#{obj}"
    @parents.unshift obj
  end

  # look up an identifier on this object, or any of its delegates
  def lookup ident
    debug "lookup #{ident} on #{self}"
    result = lookup_impl ident, []
    debug "lookup result: #{result}"
    if result.nil?
      raise VeloAttributeNotFound, "could not locate '#{ident}' on #{self}"
    end
    if result.is_a? VeloMethod
      debug "binding obtained method #{result} to object #{self}"
      result.bind_object self
    end
    result
  end

  # look up an identifier on this object, or any of its delegates
  def lookup_impl ident, trail
    debug "lookup_impl #{ident} on #{self}"
    if trail.include? self
      debug "we've already seen this object, stopping search"
      return nil
    end
    trail.push self
    if @attrs.has_key? ident
      debug "found here (#{self}), it's #{@attrs[ident]}"
      @attrs[ident]
    else
      x = nil
      for parent in @parents
        x = parent.lookup_impl ident, trail
        break if not x.nil?
      end
      x
    end
  end

  def contents
    @contents
  end
  
  def contents= c
    @contents = c
  end
end

def make_string_literal text
  o = VeloObject.new "#{@text}"
  o.velo_extend $String
  o.contents = text
  o
end
  
### establish the objectbase ###

$Object = VeloObject.new 'Object'
$Object.set 'extend', VeloMethod.new('extend', proc { |obj, args|
  obj.velo_extend args[0]
})
$Object.set 'self', VeloMethod.new('self', proc { |obj, args|
  obj
})
$Object.set 'new', VeloMethod.new('new', proc { |obj, args|
  o = VeloObject.new 'new'
  if not args[0].nil?
    o.velo_extend args[0]
  end
  o
})
$Object.set 'if', VeloMethod.new('if', proc { |obj, args|
  debug args
  method = nil
  choice = args[0].contents.empty? ? 2 : 1
  method = args[choice].lookup 'create'
  method.run [obj]
})

$String = VeloObject.new 'String'
$String.set 'concat', VeloMethod.new('concat', proc { |obj, args|
  debug "concat #{obj} #{args[0]}"
  make_string_literal(obj.contents + args[0].contents)
})
$String.set 'create', VeloMethod.new('class', proc { |obj, args|
  p = Parser.new obj.contents
  s = p.script
  s.eval args[0], []
  args[0]
})
$String.set 'method', VeloMethod.new('method', proc { |obj, args|
  # obj is the string to turn into a method
  debug "turning #{obj} into a method"
  p = Parser.new obj.contents
  s = p.script
  VeloMethod.new('*created*', proc { |obj, args|
    s.eval obj, args
  })
})
$String.set 'equals', VeloMethod.new('equals', proc { |obj, args|
  if obj.contents == args[0].contents
    make_string_literal "true"
  else
    make_string_literal ""
  end
})

$IO = VeloObject.new 'IO'
$IO.set 'print', VeloMethod.new('print', proc { |obj, args|
  puts args[0].contents
})

$Object.set 'Object', $Object
$Object.set 'String', $String
$Object.set 'IO', $IO

### ... ###

if $0 == __FILE__
  $debug = true
  $Object.set 'foo', VeloMethod.new('foo', proc { |obj, args|
    puts "foo method called on #{obj} with args #{args}!"
  })
  $String.set 'bar', VeloMethod.new('bar', proc { |obj, args|
    puts "bar method called on #{obj} with args #{args}!"
  })

  velo_Shimmy = VeloObject.new 'Shimmy'
  velo_Shimmy.velo_extend $String
  (velo_Shimmy.lookup 'bar').run [1,2,3]
end

]]--
