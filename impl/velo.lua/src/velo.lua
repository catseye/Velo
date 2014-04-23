#!/usr/bin/env lua

--[[ ========== DEBUG ========= ]]--

local debug = function(s)
    --print("--> (" .. s .. ")")
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
    local methods = {}

    methods.eval = function(obj, args)
        debug("eval #{self} on " .. obj.to_s() .. " with #{args}")
        local e = nil
        for i,expr in ipairs(exprs) do
            e = expr.eval(obj, args)
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
    local methods = {}

    methods.eval = function(obj, args)
        debug "eval #{self} on #{obj} with #{args}"
        local val = expr.eval(obj, args)
        local receiver = object.eval(obj, args)
        debug "setting #{@field} on #{receiver}"
        receiver.set(field, val)
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
    local methods = {}

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
    local methods = {}
    methods.class = "Lookup"

    debug(tostring(_receiver))
    _receiver.foo = "hi"

    methods.receiver = function()
        return _receiver
    end

    methods.ident = function()
        return _ident
    end

    methods.eval = function(obj, args)
        debug("eval " .. methods.to_s() .. " on " .. obj.to_s() .. " with #{args}")
        local receiver = _receiver.eval(obj, args)
        return receiver.lookup(_ident)
    end

    methods.to_s = function()
        return "Lookup(" .. _receiver.to_s() .. "," .. _ident .. ")"
    end

    return methods
end

MethodCall = {}
MethodCall.new = function(method_expr, exprs)
    local methods = {}

    methods.eval = function(obj, args)
        debug("eval #{self} on " .. obj.to_s() .. " with #{args}")
        local new_args = {}
        for i,expr in ipairs(exprs) do
            new_args[#new_args+1] = expr.eval(obj, args)
        end
        debug("obj = " .. obj.to_s())
        local method = method_expr.eval(obj, args)
        debug("arguments evaluated, now calling " ..
               method_expr.to_s() .. " -> " .. method.to_s())
        if method.class == "VeloMethod" then
            --# xxx show receiver (method's bound object) in debug
            debug "running real method #{method} w/args #{args}"
            return method.run(new_args)
        else
            debug("just returning non-method (" .. method.to_s() .. ") on call")
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
    local methods = {}

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
    local methods = {}

    methods.eval = function(obj, args)
        debug "eval #{self} on #{obj} with #{args}"
        return make_string_literal(text)
    end

    methods.to_s = function()
        return "StringLiteral(" .. text .. ")"
    end
    
    return methods
end

if sanity == true then
    -- SANITY TEST
    local m = MethodCall.new(Self.new(), {Argument.new(1), StringLiteral.new("jonkers")})
    local a = Assignment.new(m, "bar", Lookup.new(Self.new(), "foo"))
    s = Script.new({a, Self.new()}); print(s.to_s())
end

function isdigit(s)
    return string.find("0123456789", s, 1, true) ~= nil
end

function islower(s)
    return string.find("abcdefghijklmnopqrstuvwxyz", s, 1, true) ~= nil
end

function isupper(s)
    return string.find("ABCDEFGHIJKLMNOPQRSTUVWXYZ", s, 1, true) ~= nil
end

function isalpha(s)
    return islower(s) or isupper(s)
end

function isalnum(s)
    return isalpha(s) or isdigit(s)
end

function issep(s)
    return string.find("(),.;=", s, 1, true) ~= nil
end

--[[ ========== SCANNER ========= ]]--

Scanner = {}
Scanner.new = function(s)
    local string = s
    local _text = nil
    local _type = nil

    local methods = {}

    methods.text = function() return _text end
    methods.type = function() return _type end

    methods.is_eof = function()
        return _type == "EOF"
    end

    methods.set_token = function(text, type)
        _text = text
        _type = type
        debug("set_token " .. text .. " (" .. type .. ")")
        --#debug "string now '#{@string}'"
    end

    methods.scan = function()
        methods.scan_impl()
        debug("scanned " .. _text .. " (" .. _type .. ")")
        return _text
    end

    methods.scan_impl = function()
        -- discard leading whitespace
        while string:sub(1,1) == " " or string:sub(1,1) == "\t" do
            string = string:sub(2)
            --debug "consumed whitespace, string now '#{@string}'"
        end
        
        if string == "" then
            methods.set_token("EOF", "EOF")
            return
        end

        local match = (string:sub(1,1) == "\n" or string:sub(1,1) == "\r")
        if match then
            while match do
                string = string:sub(2)
                match = (string:sub(1,1) == "\n" or string:sub(1,1) == "\r" or
                         string:sub(1,1) == " " or string:sub(1,1) == "\t")
            end
            methods.set_token("EOL", "EOL")
            return
        end

        -- check for any single character tokens
        local c = string:sub(1,1)
        if issep(c) then
            string = string:sub(2)
            methods.set_token(c, "seperator")
            return
        end

        -- check for arguments
        if string:sub(1,1) == "#" then
            local len = 0
            while isdigit(string:sub(2+len,2+len)) and len <= string:len() do
                len = len + 1
            end
            if len > 0 then
               local argnum = string:sub(2, 2+len-1)
               string = string:sub(2+len)
               methods.set_token(argnum, "arg")
               return
            end
        end

        -- check for strings of "word" characters
        if isalnum(string:sub(1,1)) then
            local len = 0
            while isalnum(string:sub(1+len,1+len)) and len <= string:len() do
                len = len + 1
            end
            local word = string:sub(1, 1+len-1)
            string = string:sub(1+len)
            methods.set_token(word, "ident")
            return
        end

        -- literal strings
        if string:sub(1,1) == "{" then
            -- debug "scanning strlit '#{@string}'"
            local index = 2
            local level = 1
            while level > 0 do
                if string:sub(index, index) == "{" then
                    level = level + 1
                elseif string:sub(index, index) == "}" then
                    level = level - 1
                end
                index = index + 1
                if index > string:len()+1 then
                    index = string:len()+1
                    break
                end
            end
            local token = string:sub(2,index-2)
            string = string:sub(index)
            methods.set_token(token, 'strlit')
            return
        end

        debug("scanner couldn't scan '" .. string .. "'")

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
            local tstring = ""
            for i,v in ipairs(types) do
                tstring = tstring .. v .. ","
            end
            raise_VeloSyntaxError("expected '" .. tstring .. "', found '" ..
                                  _text .. "' (" .. _type .. ")")
        end
    end

    debug("created scanner with string '" .. string .. "'")
    methods.scan()

    return methods
end

if sanity == true then
    -- SANITY TEST
    x = Scanner.new(" \n  (.#53)  jonkers,031jon {sk}{str{ing}ity}w  ")
    while not x.is_eof() do
        print(x.text() .. ":" .. x.type())
        x.scan()
    end
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

]]--

Parser = {}
Parser.new = function(s)
    local scanner = Scanner.new(s)
    
    local methods = {}
    
    methods.script = function()
        debug "parsing Script production"
        local exprs = {}
        scanner.consume_type "EOL"
        local e = methods.expr()
        while e ~= nil do
            scanner.expect_types {"EOL", "EOF"}
            exprs[#exprs+1] = e
            scanner.consume_type "EOL"
            e = methods.expr()
        end
        return Script.new(exprs)
    end

    methods.expr = function()
        debug "parsing Expr production"
        if (scanner.type() == "EOL" or scanner.type() == "EOF" or
            scanner.text() == ")" or scanner.text() == ",") then
            return nil
        end
        local receiver = methods.base()  --# could be Expr, StringLit, Arg
        if (scanner.type() == "EOL" or scanner.type() == "EOF" or
            scanner.text() == ")" or scanner.text() == ",") then
            return MethodCall.new(receiver, {})
        end
        while scanner.consume '.' do
            scanner.consume_type 'EOL'
            debug "parsing .ident"
            ident = scanner.text()
            scanner.scan()
            receiver = Lookup.new(MethodCall.new(receiver, {}), ident)
        end
        if scanner.consume '=' then
            -- this is an assignment, so we must resolve the reciever chain
            -- as follows: a.b.c = foo becomes lookup(a, b).set(c, foo)
            debug "unlookuping"
            local ident = nil
            if receiver.class == "Lookup" ~= nil then
                ident = receiver.ident()
                receiver = receiver.receiver()
            else
                raise_VeloSyntaxError("assignment requires lvalue, but we have '#{@receiver}'")
            end
            debug "parsing assignment"
            scanner.consume_type 'EOL'
            e = methods.expr()
            return Assignment.new(receiver, ident, e)
        elseif scanner.type() == 'EOF' or scanner.type() == 'EOL' then
            -- this is a plain value, so we must resolve the reciever chain
            -- as follows: a.b.c becomes lookup(lookup(a, b), c)
            debug "not a method call"
            return MethodCall.new(receiver, {})
        else
            -- this is a method call, so we must resolve the reciever chain
            -- as follows: a.b.c args becomes
            -- methodcall(lookup(lookup(a, b), c), args)
            debug "parsing method call args"
            local args = {}
            local e = methods.expr()
            if e ~= nil then
                args[#args+1] = e
            end
            while scanner.consume "," do
                scanner.consume_type 'EOL'
                e = methods.expr()
                if e ~= nil then
                    args[#args+1] = e
                end
            end
            return MethodCall.new(receiver, args)
        end
    end

    methods.base = function()
        debug "parsing Base production"
        if scanner.consume "(" then
            debug "parsing parens"
            scanner.consume_type "EOL"
            e = methods.expr()
            scanner.expect ")"
            return e
        elseif scanner.type() == "strlit" then
            debug "parsing strlit"
            s = scanner.text()
            scanner.scan()
            return StringLiteral.new(s)
        elseif scanner.type() == "arg" then
            debug "parsing arg"
            num = scanner.text().to_i()
            scanner.scan()
            return Argument.new(num)
        elseif scanner.type() == "ident" then
            debug "parsing ident"
            ident = scanner.text()
            scanner.scan()
            return Lookup.new(Self.new(), ident)
        else
            raise_VeloSyntaxError("unexpected '" .. scanner.text() .. "'")
        end
    end

    return methods
end

if sanity == true then
    -- SANITY TEST
    print(Parser.new('m a, m b, c').script().to_s())
    print(Parser.new('m a, (m b, c)').script().to_s())
    print(Parser.new('m a, (m b), c').script().to_s())
end

--[[ ========== RUNTIME ========= ]]--

--# the built-in objects, for convenience of other sources
Object = nil
String = nil
IO = nil

function make_string_literal(text)
    local o = VeloObject.new(text)
    o.velo_extend(String)
    o.set_contents(text)
    return o
end

-- title is for debugging only.  methods themselves do not have names.
VeloMethod = {}
VeloMethod.new = function(title, fun)
    local _obj = nil
    
    local methods = {}
    methods.class = "VeloMethod"

    methods.bind_object = function(obj)
        debug("binding to " .. obj.to_s())
        _obj = obj
    end

    methods.run = function(args)
        fun(_obj, args)
    end

    methods.to_s = function()
        return "VeloMethod(" .. title .. ")"
    end

    return methods
end


--# parents will be [] for Object, [Object] for all other objects
VeloObject = {}
VeloObject.new = function(title)
    local parents = {}
    if Object ~= nil then
        parents[#parents+1] = Object
    end
    local attrs = {}
    local contents = nil
    local methods = {}

    methods.to_s = function()
        return "VeloObject(" .. title .. ")"
    end

    methods.set = function(ident, obj)
        attrs[ident] = obj
        if obj ~= nil then
          debug("set " .. ident .. " to " .. obj.to_s() .. " on self")
        end
    end

    --# let this object delegate to another object
    methods.velo_extend = function(obj)
        debug "extending #{self} w/#{obj}"
        table.insert(parents, 1, obj)
    end

    --# look up an identifier on this object, or any of its delegates
    methods.lookup = function(ident)
        debug "lookup #{ident} on #{self}"
        result = methods.lookup_impl(ident, {})
        debug "lookup result: #{result}"
        if result == nil then
            raise_VeloAttributeNotFound("could not locate '#{ident}' on #{self}")
        end
        if result.class == "VeloMethod" then
            debug("binding obtained method " .. result.to_s() .. " to object #{self}")
            result.bind_object(methods) -- self!!!
        end
        return result
    end

    --# look up an identifier on this object, or any of its delegates
    methods.lookup_impl = function(ident, trail)
        debug "lookup_impl #{ident} on #{self}"
        --[[
        if trail.include? methods
          debug "we've already seen this object, stopping search"
          return nil
        end
        ]]--
        trail[#trail+1] = methods
        if attrs[ident] ~= nil then
            debug("found here " .. methods.to_s() .. ", it's #{@attrs[ident]}")
            return attrs[ident]
        else
            local x = nil
            for i,parent in ipairs(parents) do
                x = parent.lookup_impl(ident, trail)
                if x ~= nil then
                    break
                end
            end
            return x
        end
    end

    methods.contents = function()
        return contents
    end
  
    methods.set_contents = function(c)
        contents = c
    end

    return methods
end

--[[ -------------- objectbase ----------- ]]--

Object = VeloObject.new 'Object'
Object.set('extend', VeloMethod.new('extend', function(obj, args)
    return obj.velo_extend(args[0])
end))

Object.set('self', VeloMethod.new('self', function(obj, args)
    return obj
end))
Object.set('new', VeloMethod.new('new', function(obj, args)
    local o = VeloObject.new 'new'
    if args[1] ~= nil then
        o.velo_extend(args[1])
    end
    return o
end))

Object.set('if', VeloMethod.new('if', function(obj, args)
    debug(tostring(args))
    local method = nil
    local choice = 2
    local cont = args[1].contents()
    if #cont == 0 then
        choice = 3
    end
    method = args[choice].lookup 'create'
    method.run {obj}
end))

String = VeloObject.new 'String'

String.set('concat', VeloMethod.new('concat', function(obj, args)
  debug "concat #{obj} #{args[0]}"
  return make_string_literal(obj.contents() .. args[1].contents())
end))

String.set('create', VeloMethod.new('class', function(obj, args)
  local p = Parser.new(obj.contents())
  local s = p.script()
  debug("create! " .. obj.to_s())-- .. ", " .. args[1].to_s())
  s.eval(args[1], {})
  return args[1]
end))

String.set('method', VeloMethod.new('method', function(obj, args)
    -- obj is the string to turn into a method
    debug "turning #{obj} into a method"
    local p = Parser.new(obj.contents())
    local s = p.script()
    return VeloMethod.new('*created*', function(obj, args)
        return s.eval(obj, args)
    end)
end))

String.set('equals', VeloMethod.new('equals', function(obj, args)
    if obj.contents() == args[1].contents() then
        return make_string_literal("true")
    else
        return make_string_literal("")
    end
end))


IO = VeloObject.new 'IO'
IO.set('print', VeloMethod.new('print', function(obj, args)
    print(args[1].contents())
end))

Object.set('Object', Object)
Object.set('String', String)
Object.set('IO', IO)


if sanity == true then
    -- SANITY TEST
    Object.set('foo', VeloMethod.new('foo', function(obj, args)
        print "foo method called on #{obj} with args #{args}!"
    end))
    String.set('bar', VeloMethod.new('bar', function(obj, args)
        print "bar method called on #{obj} with args #{args}!"
    end))
    local Shimmer = VeloObject.new 'Shimmer'
    print(String.to_s())
    Shimmer.velo_extend(String)
    local bar = Shimmer.lookup('bar')
    print(bar.to_s())
    bar.run {1,2,3}
end

--[[ ================== MAIN =============== ]]--

text = ""
for line in io.lines(arg[1]) do
    text = text .. line
end

local p = Parser.new(text)
local s = p.script()
local o = VeloObject.new('main-script')
s.eval(o, {})   -- XXX could pass command-line arguments here...
