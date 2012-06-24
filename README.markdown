Velo
====

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

Conditional statements are implemented by a method on strings.

    | extend IO
    | {5 > 4}.if {print {Yes}}, {print {No}}
    = Yes

To try to hammer this block-is-a-string thing home, you can just
as easily call a method on a string variable as a string literal.

    | extend IO
    | a = {4 > 5}
    | a.if {print {Yes}}, {print {No}}
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

    | extend IO
    | a = {7}.concat {>}.concat {5}
    | a.if {print {Yes}}, {print {No}}
    = Yes

Scripts as Classes
------------------

Classes can be defined within a script:

    | Jonkers = {
    |   extend IO
    |   print {What?}
    | }.class
    | Jonkers.new
    = What?

Note that `class` is a method on strings.

The fact that classes can be defined in a script, and that scripts are
no different from classes, means that classes can be defined within a
class:

    | Jonkers = {
    |   Fordible = {
    |     extend IO
    |     print {Sure}
    |   }.class
    |   Fordible.new
    | }.class
    | Jonkers.new
    = Sure

Our demonstrations above show that a class has a "body" of code which
is run when it is instantiated by a call to its `new` method -- more
or less, just like a script.  No particular constructor method is needed,
as the code inside the class can take care of initializing the instance.

Note that this differs from how code like this is handled in Ruby; in
that language, the code inside the class is executed when the class is
defined.  In Velo, it is only run when the class is instantiated.

(Note: I don't think the preceding idea is practicable anymore.
That code needs to run to set up the (class) object, and we shan't
artificially distinguish between subsets of that code for different
purposes.  We probably need something like Ruby's `initialize`.)

    | Jonkers = {
    |   extend IO
    |   print {Sure}
    | }.class
    | Jonkers.new
    | Jonkers.new
    = Sure
    = Sure

    | extend IO
    | Jonkers = {
    |   Fordible = {
    |     extend IO
    |     print {Sure}
    |   }.class
    |   Fordible.new
    | }.class
    | print {Done}
    = Done

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

Typically, a class will define some methods.

    | Jonkers = {
    |   announce = {
    |     IO.print {This is }.concat {Maeve}
    |   }.method {}
    | }.class
    | j = Jonkers.new
    | j.announce
    = This is Maeve

Which means a script can have methods.

    | announce = {
    |   IO.print {This is }.concat {Vern}
    | }.method {x}
    | announce
    = This is Vern

So, yeah, `method` is a method on strings too, just like `class`.  The
argument is a string which is a list of formal parameter names.

Methods can have arguments:

    | announce = {
    |   IO.print {This is }.concat x
    | }.method {x}
    | announce {Raina}
    = This is Raina

The block used to define a class or method is, of course, just a string,
and can be a string variable.

    | extend IO
    | a = {print x}
    | announce = a.method {x}
    | announce {Hallo}
    = Hallo

    | a = {extend IO; print {What?}}
    | Jonkers = a.class
    | Jonkers.new
    = What?

    | {extend IO; print {Yes!}}.class.new
    = Yes!

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
    |   def announce(x) {
    |     print {This is }.concat x
    |   }
    | }.class
    | Jeepers = {
    |   extend Jonkers
    | }.class
    | j = Jeepers.new
    | j.announce {Luke}
    = This is Luke

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
    |   def announce(x) {
    |     print {This is }.concat x
    |   }
    | }.class
    | extend Jonkers
    | announce {Ike}
    = This is Ike

The block given to `extend` is just a string, of course.

    | extend {extend IO; p = {print x}.method {x}}.class
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

    | class Jonkers {
    |   def foo { 14 }
    | }
    | class Jeepers {
    |   def foo { 29 }
    | }
    | class Jeskers {
    |   extend Jonkers
    |   extend Jeepers
    |   def bar = { foo }
    | }
    | extend IO
    | j = Jeskers.new
    | print j.bar
    = 29

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

    | class McTavish {
    |   def bar(j) { j.hey }
    | }
    | class Jeskers {
    |   extend IO
    |   def bar(m) { m.bar self }
    |   def hey { print {Hey!} }
    | }
    | m = McTavish.new
    | j = Jeskers.new
    | j.bar(m)
    = Hey!

Appendix
========

(This is all very slapdash right now.)

Summary of methods on `Object`
------------------------------

*   `extend` <string>
*   `self`
*   `new` ...
*   `Object`, `String`, `IO`, and all other predefined classes

Summary of methods on `String`
------------------------------

*   `if` <string>, <string>
*   `while` <string>
*   `class`
*   `method` <string>
*   `concat` <string>
*   `eval` <string>

Summary of methods on `IO`
--------------------------

*   `print` <string>
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

TODO
----

*   Delineate the scoping rules more rigorously, e.g. figure out where
    variables local to methods belong.
*   Possibly unify scripts and strings.  (A script is just a string,
    after all.)
*   Possibly unify methods and scripts.  (A method is just a script,
    after all.)
*   Talk about how scripts and modules can be unified similarly.
*   Contrast with Ruby (e.g. toplevel methods being put on `Object`,
    but as private methods.)
*   Implement a Velo interpreter, or try to, to shake out the
    inconsistencies which are doubtless lurking here.
