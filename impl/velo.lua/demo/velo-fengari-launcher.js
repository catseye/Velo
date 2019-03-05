function launch(config) {
  config.container.innerHTML = ('' +
    '<textarea id="editor" rows="10" cols="80">' +
    'extend IO\n' +
    'a = {Hello, world!}\n' +
    'print a\n' +
    '</textarea>' +
    '<button onclick="run()">Run</button>' +
    '<pre id="output"></pre>');
}

function setUpPrint(elem) {
  elem.innerHTML = '';
  fengari.interop.push(fengari.L, function() {
    var s = fengari.interop.tojs(fengari.L, 2);
    elem.innerHTML += s + "\n";
  });
  fengari.lua.lua_setglobal(fengari.L, "veloPrint");
}

function loadVeloProg(progText) {
  fengari.interop.push(fengari.L, progText);
  fengari.lua.lua_setglobal(fengari.L, "veloProg");
}

function runVeloProg() {
  var luaProg = `
    local program = Parser.new(veloProg)
    local script = program.script()
    local object = VeloObject.new('main-script')
    local result = script.eval(object, {})
    return result
  `;

  fengari.load(luaProg)();
}

function run() {
  setUpPrint(document.getElementById("output"));
  loadVeloProg(document.getElementById("editor").value);
  runVeloProg();
}
