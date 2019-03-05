examplePrograms = [
    [
        "class.velo", 
        "Jonkers = {\n  IO.print {Hello}\n}.create new\n"
    ], 
    [
        "concat.velo", 
        "IO.print ({Hello, }.\n  concat {world!})\n"
    ], 
    [
        "hello-world.velo", 
        "extend IO\na = {Hello, world!}\nprint a\n"
    ], 
    [
        "if.velo", 
        "yes = {IO.print {Yes}}\nno = {IO.print {No}}\nif ({X}.equals {Y}), yes, no\nif ({X}.equals {X}), yes, no\n"
    ], 
    [
        "method-args.velo", 
        "bar = {IO.print {Hello, }.concat #1}.method\nbar {there.}\n"
    ], 
    [
        "recur.velo", 
        "count = {\n  temp = #1\n  if (temp.equals {XXXXXX}), { IO.print {Done!}}, {\n    IO.print temp\n    count temp.concat {X}\n  }\n}.method\ncount {X}\n"
    ], 
    [
        "script-method.velo", 
        "eeyore = IO\nfoo = {eeyore.print {Hello, world!  Sincerely yours, foo.}}.method\nfoo\n"
    ]
];
