velo.lua
========

This directory contains an implementation of Velo in Lua 5.1,
called `velo.lua`.  Its source resides in the `src` subdirectory.

It also contains a demonstration of running `velo.lua` in a
web browser, under [Fengari][], in the `demo` subdirectory.

In order to for this demonstration to work locally, you'll need
to run a local webserver from the *root* directory of this
repository.  For example, if you have Python installed,

    python -m SimpleHTTPServer

Then open

    http://127.0.0.1:8000/impl/velo.lua/demo/velo.html

in your web browser.  If you don't have Python, other options
(and more information on running web installations locally)
can be found here: [how to run things locally][].

Additionally, in the `bin` directory in the root of this repo,
there is a driver script called `velo_lua` whose purpose is to
properly run `velo.lua` regardless of the current directory.
In other words, you can just put that bin dir on your `PATH`
and type `velo_lua` to run it.

[Fengari]: https://fengari.io/
[how to run things locally]: https://github.com/mrdoob/three.js/wiki/How-to-run-things-locally#run-local-server