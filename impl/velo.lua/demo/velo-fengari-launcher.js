function launch(config) {
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
