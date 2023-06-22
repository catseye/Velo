-- Usage:
--   LUA_PATH="?.lua" lua velo_tests.lua

table = require "table"

r = require "velo"

-- Script

local m = MethodCall.new(Self.new(), {Argument.new(1), StringLiteral.new("jonkers")})
local a = Assignment.new(m, "bar", Lookup.new(Self.new(), "foo"))
s = Script.new({a, Self.new()}); print(s.to_s())

-- Scanner

x = Scanner.new(" \n  (.#53)  jonkers,031jon {sk}{str{ing}ity}w  ")
while not x.is_eof() do
    print(x.text() .. ":" .. x.type())
    x.scan()
end

-- Parser

print(Parser.new('m a, m b, c').script().to_s())
print(Parser.new('m a, (m b, c)').script().to_s())
print(Parser.new('m a, (m b), c').script().to_s())

-- Objects

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
