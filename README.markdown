Velo
====

_Language version 0.1, distribution revision 2012.0714_

> "Jaws was never my scene, and I don't like Star Wars."  
> -- Queen, "Bicycle Race"

Velo is an object-oriented language, inspired somewhat by Ruby,
and sharing somewhat Robin's "radically goo-oriented" approach.

(I don't really like the term "scripting language", but it seems
to be fitting here, for whatever reason, so where I might normally
say "program" I will instead say "script".)

We shall introduce Velo with a series of simple examples in
Falderal format.  The design of Velo is still somewhat inchoate,
so do not expect all of these examples to be perfectly consistent
or even necessarily feasible.

    -> Tests for functionality "Interpret Velo Script"

First, the ubiquitous "Hello, world!":

    | extend IO
    | print {Hello, world!}
    = Hello, world!

This example demonstrates what are likely the two most outstanding
features of Velo:

*   Scripts are no different from object classes.  Thus, `extend`
    is used in the very same manner as an "import" or "require"
    construct would be in some other language; it is not dissimilar
    to Ruby's `include` method.
*   Literal strings are delimited by curly braces.  In fact, in Velo,
    strings are no different from code blocks.

Let those two ideas sink in for a moment, then we'll continue.

Strings as Blocks
-----------------

Conditional statements are implemented by a method called `if`.
This method is on the root object, called `Object`, from which all
objects, including your script, descend.

    | if ({X}.equals {X}), {IO.print {Yes}}, {IO.print {No}}
    = Yes

    | if ({X}.equals {Y}), {IO.print {Yes}}, {IO.print {No}}
    = No

To try to hammer this block-is-a-string thing home, you can just
as easily call this method with arguments that are string variables,
rather than string literals (that look like blocks of code.)

    | yes = {IO.print {Yes}}
    | no = {IO.print {No}} 
    | if ({X}.equals {Y}), yes, no 
    = No

You may be thinking that this is basically an implicit and
ubiquitous use of `eval` -- which would be accurate -- and that that
means that execution of Velo code inevitably suffers in efficiency --
which is not accurate.  When the string being `eval`ed is a literal
string, it can be transformed into the internal format for code as
early as possible, making it no less efficient than any other code.
It's only when you have to `eval` a string in a variable, where you
can't predict what it will be until you evaluate the surrounding code,
that you necessarily take a performance hit.

    | p = {extend IO; print }
    | yes = p.concat {{Yes}}
    | no = p.concat {{No}}
    | if ({X}.equals {X}), yes, no
    = Yes

(The above example would be even more persuasive if `yes` and `no`
were constructed from user input, or a random selection, but those
are more difficult to present as readable, automated test cases.)

Scripts as Classes
------------------

Classes can be defined within a script:

    | Jonkers = {
    |   IO.print {What?}
    | }.create new
    = What?

Note that `create` is a method on strings, and it takes a parameter,
which in this case is the result of calling the method `new` (to be
explained later.)  The class itself has a "body" of code which is run when
the class is defined, not unlike the situation in Ruby.  This code can be
used to set up class-level attributes:

    | Jonkers = {
    |   name = {Ulysses}
    | }.create new
    | IO.print Jonkers.name
    = Ulysses

Normally a class will also have some methods, but we'll cover that later.

The fact that classes can be defined in a script, and that scripts are
no different from classes, means that classes can be defined within a
class:

    | Jonkers = {
    |   Fordible = {
    |     extend IO
    |     print {Sure}
    |   }.create new
    | }.create new
    = Sure

Our demonstrations above show that a class has a "body" of code which
is run when it is defined with `create`.

The block used to define a class, of course, is just a string, and can be
a string variable.

    | a = {extend IO; print {What?}}
    | Jonkers = a.create new
    | Jonkers.new
    = What?

    | {extend IO; print {Yes!}}.create new
    = Yes!

What's happening here is actually this.

The `new` method, inherited from `Object`, creates a new, almost
featureless object; its only feature is that it inherits from `Object`.

    | a = new
    | a.IO.print {A new object inherits IO from Object.}
    = A new object inherits IO from Object.

The `create` method, inherited from `String`, runs its receiver, as a
script, on the object passed to it.  This may seem an odd usage of the
word "create", as in our examples above, it's actually `new` that
creates the object.  But in English, the word "create" does sometimes
have this meaning; for example, a royal subject can be "created a knight".
And, in Velo, there is nothing preventing you from passing an existing
object to `create`.

    | Jonkers = {foo = {123}}.create new
    | {bar = {456}}.create Jonkers
    | IO.print Jonkers.bar
    = 456

Aside on Syntax
---------------

We've been so busy describing these remarkable qualities of Velo that
we haven't said much about the basic properties of its syntax.  Some
may be obvious from the examples, but there are probably points worth
clarifying here.

A Velo script is simply a list of expressions, seperated by end-of-line
markers, with a few qualifications:

*   A sequence of linefeeds and carriage returns is an end-of-line
    marker.
*   The token `;` is also considered an end-of-line marker.
*   A series of end-of-line markers, possibly with intervening whitespace,
    is considered a single end-of-line marker.
*   An end-of-line marker can optionally occur after the tokens `(`,
    `=`, and `,`, without terminating the expression.
*   An end-of-line marker can optionally appear before any expression
    in a script, so that blank lines can appear at the start of a script.

Some examples of these properties follow.

    | IO.print {Hi}; IO.print {there}
    = Hi
    = there

    | 
    | 
    | IO.print {Hi}
    | 
    | 
    | IO.print {there}
    = Hi
    = there

    | IO.print (
    |   {Hi there})
    = Hi there

    | a =
    |   {Hi there}
    | IO.print a
    = Hi there

    | if {true},
    |   {IO.print {Yes}},
    |   {IO.print {No}}
    = Yes

A method call is followed by a list of arguments seperated by commas.
(You saw this above with the `if` method.)  Velo does not statically
record the arity of a method, so you can pass any number of arguments
that you want (but of course, the method may fail if it is not given the
number it expects.)  The parser tells when a method call ends by the
fact that there are no more commas (it instead ran into a `)` or an
end-of-line marker or the end of the file.)

Method calls can be chained:

    object.method.another.yetmore

Parentheses can be used to disambiguate when there are arguments in
the method calls in the chain:

    object.method a, object.method b, c
    object.method a, (object.method b, c)
    object.method a, (object.method b), c

Lines 1 and 2 above are equivalent, but line 3 is different.

Now, about those Methods
------------------------

Typically, a class will define some methods.  (For now, let's think of them
as class methods.)

    | Jonkers = {
    |   announce = {
    |     IO.print {This is }.concat {Maeve}
    |   }.method
    | }.create new
    | Jonkers.announce
    = This is Maeve

Which means a script can have methods.

    | announce = {
    |   IO.print {This is }.concat {Vern}
    | }.method
    | announce
    = This is Vern

Note that, unlike Ruby, this method is actually defined on the script.
(When a method is defined at the toplevel in Ruby, it is actually placed
in `Kernel`, and placed on `Object` as a private method.  There is probably
some historical or byzantine architectural reason for this, but it struck me
as quite bizarre when I learned about it.)

So, yeah, `method` is a method on strings too, just like `create`.  It takes
no arguments.

But, methods can have arguments, when called.  In their definition, the
first argument is referred to by `#1`, the second by `#2`, etc.

    | announce = {
    |   IO.print {This is }.concat #1
    | }.method
    | announce {Raina}
    = This is Raina

The block used to define a method is, of course, just a string.

    | a = {IO.print {This is }.concat #1}
    | announce = a.method
    | announce {Naoko}
    = This is Naoko

A method may be recursive.

    | count = {
    |   temp = #1
    |   if (temp.equals {XXXXXX}), { IO.print {Done!}}, {
    |     IO.print temp
    |     count temp.concat {X}
    |   }
    | }.method
    | count {X}
    = X
    = XX
    = XXX
    = XXXX
    = XXXXX
    = Done!

Note, however, that a method is not a Velo object, at least not in this
early version of Velo.  The only operation that is defined on the
result of calling the `method` method on a string, is assigning it to
an attribute of an object, from whence it can be called.  Trying to
do anything else to it (pass it to another method, for example) is not
defined.

Instantiation
-------------

Classes can be instantiated.  The most straightforward way to do this
is to use the `new` method we already discussed; in truth, it takes an
optional argument, and if this is given, the new object extends the object
passed to `new`.

    | Jonkers = {
    |   announce = {
    |     IO.print {This is }.concat #1
    |   }.method
    | }.create new
    | j = new Jonkers
    | j.announce {Jamil}
    | k = new Jonkers
    | k.announce {Brian}
    = This is Jamil
    = This is Brian

This usage of `new` is just a shortcut, because you can always `extend`
the new object yourself.

    | Jonkers = {
    |   announce = {
    |     IO.print {This is }.concat #1
    |   }.method
    | }.create new
    | j = new; j.extend Jonkers
    | j.announce {Jamil}
    = This is Jamil

Instances of classes have their own attributes, but obtain anything
they might be missing, from the class.

    | Jonkers = {
    |   name = {Cheryl}
    |   announce = {
    |     IO.print {This is }.concat name
    |   }.method
    | }.create new
    | 
    | j = new Jonkers
    | j.announce
    | k = new Jonkers
    | { name = {David} }.create k
    | k.announce
    = This is Cheryl
    = This is David

We said `{ name = {David} }.create k` above because, when the test was
written, we couldn't say simply `k.name = {David}` yet.  Now we can, so
let's try that:

    | Jonkers = {
    |   name = {James}
    |   announce = {
    |     IO.print {This is }.concat name
    |   }.method
    | }.create new
    | 
    | j = new Jonkers
    | j.announce
    | k = new Jonkers
    | k.name = {Joyce}
    | k.announce
    = This is James
    = This is Joyce

Given what you see above, you might be wondering exactly the difference
between classes and objects is.  Well...

Delegation
----------

We've been talking about classes as if they were a distinct language
construct, but really, a class is just a relationship between objects.

Velo uses prototype-based object-orientation.  Each object has a list
of parent objects; these are its classes.  But they're just objects.

When a method is called on an object, if that method is not defined
on that object, its parent objects are checked for that method; if any
are found, that method on the parent is called, but with the target
object as "self".

    | Jonkers = {
    |   extend IO
    |   announce = {
    |     print {This is }.concat #1
    |   }.method
    | }.create new
    | Jeepers = {
    |   extend IO
    |   greet = {
    |     print {Hello, }.concat #1
    |   }.method
    | }.create new
    | Jeepers.extend Jonkers
    | 
    | j = new Jeepers
    | j.announce {Luke}
    | j.greet {Luke}
    = This is Luke
    = Hello, Luke

(We had to say `Jeepers.extend Jonkers` in the above, instead of saying
`extend Jonkers` in the definition of Jeepers, because inside that
definition, Jonkers was not in scope.  This would be a nice thing to fix...)

When you say `extend`, you are just adding another object to the list
of parent objects for a class.

If a method is not found on an object, nor any of its parent objects,
it is looked for on the built-in object `Object`.  (If it is not there
either, an exception is thrown.)

In fact, `extend` is itself a method on `Object`.  When it is executed,
it evaluates its string parameter to obtain an object, and adds that
object to the list of parent objects of the current object.

Since scripts are no different from classes, a script can `extend`
a class that it defines:

    | Jonkers = {
    |   extend IO
    |   announce = {
    |     print {This is }.concat #1
    |   }.method
    | }.create new
    | extend Jonkers
    | announce {Ike}
    = This is Ike

The class doesn't even have to be given a name.

    | extend {extend IO; p = {print #1}.method}.create new
    | p {Hello!}
    = Hello!

Multiple Inheritance
--------------------

Because `extend` can be called as many times as you like on an
object, an object can inherit from (delegate to) as many classes
as you like.

For multiple inheritance, the method resolution order follows the
source code order; the objects added as parent objects by more
recently executed `extend`s are searched before those added by
earlier executed `extend`s.

    | Jonkers = {
    |   foo = { IO.print {fourteen} }.method
    | }.create new
    | Jeepers = {
    |   foo = { IO.print {twenty-nine} }.method
    | }.create new
    | 
    | Jeskers = {
    |   bar = { foo }.method
    | }.create new
    | Jeskers.extend Jonkers
    | Jeskers.extend Jeepers
    | 
    | j = new Jeskers; j.bar
    | 
    | Jofters = {
    |   bar = { foo }.method
    | }.create new
    | Jofters.extend Jeepers
    | Jofters.extend Jonkers
    | 
    | j = new Jofters; j.bar
    = twenty-nine
    = fourteen

`self`
------

As you've noticed, Velo has an "implicit self" -- invoking a method
just invokes it on the current self (which may be the script.)
But sometimes you need to explicitly refer to self, for example, to
pass it to some other method.

For this purpose, the `Object` object provides the method `self`
which simply returns the object it is called on.  Since all objects
effectively "inherit" (read: delegate to, when all other options
are exhausted) from `Object`, they can all use this "explicit self".

    | a = {X}
    | IO.print a.equals(a.self)
    = true

    | McTavish = {
    |   bar = { a = #1; a.hey }.method
    | }.create new
    | Jeskers = {
    |   bar = { a = #1; a.bar self }.method
    |   hey = { IO.print {Hey!} }.method
    | }.create new
    | Jeskers.bar McTavish
    = Hey!

Appendix
========

(This is all very slapdash right now.)

Summary of methods on `Object`
------------------------------

*   `extend` STRING
*   `self`
*   `new` ...
*   `Object`, `String`, `IO`, and all other predefined classes

Summary of methods on `String`
------------------------------

*   `if` STRING, STRING
*   `while` STRING
*   `class`
*   `method` STRING
*   `concat` STRING
*   `eval` STRING

Summary of methods on `IO`
--------------------------

*   `print` STRING
*   `input`

Grammar
-------

    Velo ::= {[EOL] Expr EOL}.
    Expr ::= Name "=" [EOL] Expr
           | Expr {"." [EOL] Name} [Expr {"," [EOL] Expr}]
           | Name
           | "(" [EOL] Expr ")"
           | StringLiteral
           .

Future Work
-----------

*   Unify scripts and strings.  (A script is just a string, after all.)
*   Unify methods and scripts.  (A method is just a script, after all.)
*   Unify scripts and modules.  (A module is just a script, after all.)
    Unfortunately, the Falderal format doesn't make this easy to
    illustrate; but there is no reason that we shouldn't be able to
    load external files as objects.

