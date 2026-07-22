-- Test harness for mime-determiner.yazi/main.lua
-- Stubs yazi's global API and runs M:fetch against synthetic jobs.
-- Run: lua test_harness.lua

local results = { pass = 0, fail = 0 }
local function check(name, cond, detail)
  if cond then
    results.pass = results.pass + 1
    print(string.format("  PASS %s", name))
  else
    results.fail = results.fail + 1
    print(string.format("  FAIL %s%s", name, detail and ("  -- " .. detail) or ""))
  end
end

-- -------------------------------------------------------------------
-- Stubs for yazi globals
-- -------------------------------------------------------------------

local function make_url(name)
  -- Url must be usable as a table key and expose .name
  return setmetatable({ name = name, _str = "/cwd/" .. (name or "") }, {
    __tostring = function(self) return self._str end,
  })
end

local function make_file(name, opts)
  opts = opts or {}
  return {
    url = make_url(name),
    cha = { is_dummy = opts.dummy or false, len = opts.len or 100 },
    hash = function() return name end,
  }
end

-- Command stub: configurable per-test via _G.MAGICA_OUTPUTS
local Command = {}
Command.__index = Command
function Command.new(cmd)
  return setmetatable({ _cmd = cmd, _args = {}, _stdout_mode = nil, _stderr_mode = nil, _spawn_fails = false }, Command)
end
function Command:arg(a) self._args[#self._args + 1] = a; return self end
function Command:args(list) for _, a in ipairs(list) do self._args[#self._args + 1] = a end; return self end
function Command:stdout(mode) self._stdout_mode = mode; return self end
function Command:stderr(mode) self._stderr_mode = mode; return self end
function Command:spawn()
  if self._spawn_fails then return nil, "spawn error" end
  local url_str = self._args[#self._args]
  local child = {
    _url = url_str,
    wait_with_output = function(c)
      local out = _G.MAGIKA_OUTPUTS and _G.MAGIKA_OUTPUTS[c._url]
      if out == nil then
        return { status = { success = false, code = 1 }, stdout = "", stderr = "" }
      end
      return { status = { success = true, code = 0 }, stdout = out, stderr = "" }
    end,
  }
  _G.SPAWN_COUNT = (_G.SPAWN_COUNT or 0) + 1
  table.insert(_G.SPAWN_LOG, url_str)
  return child
end

-- Reconstruct the chain used by the plugin: Command("magika"):arg(...):...
_G.Command = setmetatable({}, {
  __call = function(_, cmd) return Command.new(cmd) end,
})
Command.PIPED = "piped"
Command.NULL = "null"
Command.INHERIT = "inherit"
_G.Command.PIPED = Command.PIPED
_G.Command.NULL = Command.NULL
_G.Command.INHERIT = Command.INHERIT

-- ya stub
local emitted = {}
_G.ya = {
  emit = function(event, payload) emitted[#emitted + 1] = { event = event, payload = payload } end,
  hide = function() return function() end end,
  dbg = function(_) end,
  err = function(_) end,
}

-- -------------------------------------------------------------------
-- Load the plugin under test
-- -------------------------------------------------------------------
package.path = package.path .. ";./?.lua"
local main_ok, M = pcall(require, "main")
if not main_ok then
  -- dofile fallback
  M = dofile("main.lua")
end

-- -------------------------------------------------------------------
-- Tests
-- -------------------------------------------------------------------

print("mime-determiner.yazi test harness")
print(string.rep("-", 50))

-- Test 1: M:fetch returns a FetchState (not nil) — reproduces the reported error
do
  _G.MAGIKA_OUTPUTS = {}
  _G.SPAWN_LOG = {}
  _G.SPAWN_COUNT = 0
  emitted = {}
  local job = { files = { make_file("foo.txt"), make_file("bar.lua") } }
  local state = M:fetch(job)
  check("fetch returns non-nil state", state ~= nil, "got: " .. tostring(state))
  check("state is table", type(state) == "table", "got: " .. type(state))
  if type(state) == "table" then
    check("state has 2 entries", #state == 2, "got: " .. #state)
    check("state[1] is boolean", type(state[1]) == "boolean", "got: " .. type(state[1]))
    check("state[2] is boolean", type(state[2]) == "boolean", "got: " .. type(state[2]))
  end
end

-- Test 2: ext_mime fallback works when magika fails
do
  _G.MAGIKA_OUTPUTS = {}  -- magika always fails
  _G.SPAWN_LOG = {}
  _G.SPAWN_COUNT = 0
  emitted = {}
  local job = { files = { make_file("script.sh"), make_file("unknown.xyz") } }
  local state = M:fetch(job)
  local upd = emitted[1] and emitted[1].payload.updates or {}
  check("ext fallback .sh -> text/x-shellscript", upd[job.files[1].url] == "text/x-shellscript",
    "got: " .. tostring(upd[job.files[1].url]))
  check("unknown.xyz has no mime", upd[job.files[2].url] == nil)
  if type(state) == "table" then
    check("state[1] true (got mime via ext)", state[1] == true)
    check("state[2] false (no mime)", state[2] == false)
  end
end

-- Test 3: magika output parsed correctly
do
  _G.MAGIKA_OUTPUTS = { ["/cwd/data.bin"] = "data.bin: application/x-elf\n" }
  _G.SPAWN_LOG = {}
  _G.SPAWN_COUNT = 0
  emitted = {}
  local job = { files = { make_file("data.bin") } }
  local state = M:fetch(job)
  local upd = emitted[1] and emitted[1].payload.updates or {}
  check("magika mime parsed", upd[job.files[1].url] == "application/x-elf",
    "got: " .. tostring(upd[job.files[1].url]))
  check("state[1] true", state and state[1] == true)
end

-- Test 4: generic mime filtered out, falls back to ext
do
  _G.MAGIKA_OUTPUTS = { ["/cwd/blob.dat"] = "blob.dat: application/octet-stream\n" }
  _G.SPAWN_LOG = {}
  emitted = {}
  local job = { files = { make_file("blob.dat") } }
  local state = M:fetch(job)
  local upd = emitted[1] and emitted[1].payload.updates or {}
  check("generic octet-stream filtered", upd[job.files[1].url] == nil,
    "got: " .. tostring(upd[job.files[1].url]))
end

-- Test 5: concurrency cap — more files than MAX_CONCURRENT should not exceed cap
do
  _G.MAGIKA_OUTPUTS = {}
  _G.SPAWN_LOG = {}
  _G.SPAWN_COUNT = 0
  emitted = {}
  local files = {}
  for i = 1, 20 do files[#files + 1] = make_file(string.format("f%02d.txt", i)) end
  M:fetch({ files = files })
  -- At any point, pending queue must not exceed MAX_CONCURRENT (8).
  -- Since we drain one-per-spawn after cap, max outstanding == MAX_CONCURRENT.
  check("spawn count == file count (all spawned)", _G.SPAWN_COUNT == 20,
    "got: " .. tostring(_G.SPAWN_COUNT))
  -- Verify cap logic: we can't directly observe peak outstanding, but we can
  -- confirm the drain happened by checking spawn order matches file order.
  check("spawns in file order", _G.SPAWN_LOG[1] == "/cwd/f01.txt" and _G.SPAWN_LOG[20] == "/cwd/f20.txt")
end

-- Test 6: update_mimes emitted with Url-object keys (not stringified)
do
  _G.MAGIKA_OUTPUTS = { ["/cwd/x.toml"] = "x.toml: text/plain\n" }
  _G.SPAWN_LOG = {}
  emitted = {}
  local job = { files = { make_file("x.toml") } }
  M:fetch(job)
  check("emit event is update_mimes", emitted[1] and emitted[1].event == "update_mimes")
  local upd = emitted[1] and emitted[1].payload.updates or {}
  -- The key should be the Url object (table), not a string
  local key_type = nil
  for k in pairs(upd) do key_type = type(k); break end
  check("update key is Url object (table)", key_type == "table",
    "got: " .. tostring(key_type))
end

-- Test 7: dotfile with no real extension (.bashrc) -> ext "bashrc" -> no match -> nil
do
  _G.MAGIKA_OUTPUTS = {}
  _G.SPAWN_LOG = {}
  emitted = {}
  local job = { files = { make_file(".bashrc") } }
  local state = M:fetch(job)
  local upd = emitted[1] and emitted[1].payload.updates or {}
  check(".bashrc yields no ext mime", upd[job.files[1].url] == nil)
  if type(state) == "table" then
    check(".bashrc state false", state[1] == false)
  end
end

-- Test 8: filename match (Makefile) overrides extension lookup
do
  _G.MAGIKA_OUTPUTS = {}
  _G.SPAWN_LOG = {}
  emitted = {}
  local job = { files = { make_file("Makefile") } }
  M:fetch(job)
  local upd = emitted[1] and emitted[1].payload.updates or {}
  check("Makefile -> text/makefile", upd[job.files[1].url] == "text/makefile",
    "got: " .. tostring(upd[job.files[1].url]))
end

-- -------------------------------------------------------------------
print(string.rep("-", 50))
print(string.format("RESULTS: %d passed, %d failed", results.pass, results.fail))
os.exit(results.fail == 0 and 0 or 1)