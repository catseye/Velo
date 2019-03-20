examplePrograms = [
    {
        "contents": "Jonkers = {\n  IO.print {Hello}\n}.create new\n", 
        "filename": "class.velo"
    }, 
    {
        "contents": "IO.print ({Hello, }.\n  concat {world!})\n", 
        "filename": "concat.velo"
    }, 
    {
        "contents": "extend IO\na = {Hello, world!}\nprint a\n", 
        "filename": "hello-world.velo"
    }, 
    {
        "contents": "yes = {IO.print {Yes}}\nno = {IO.print {No}}\nif ({X}.equals {Y}), yes, no\nif ({X}.equals {X}), yes, no\n", 
        "filename": "if.velo"
    }, 
    {
        "contents": "bar = {IO.print {Hello, }.concat #1}.method\nbar {there.}\n", 
        "filename": "method-args.velo"
    }, 
    {
        "contents": "count = {\n  temp = #1\n  if (temp.equals {XXXXXX}), { IO.print {Done!}}, {\n    IO.print temp\n    count temp.concat {X}\n  }\n}.method\ncount {X}\n", 
        "filename": "recur.velo"
    }, 
    {
        "contents": "eeyore = IO\nfoo = {eeyore.print {Hello, world!  Sincerely yours, foo.}}.method\nfoo\n", 
        "filename": "script-method.velo"
    }
];
