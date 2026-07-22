local M = {}

local filenames = {
  ["makefile"] = "text/makefile",
  ["gnumakefile"] = "text/makefile",
  ["dockerfile"] = "text/plain",
  ["justfile"] = "text/plain",
  ["license"] = "text/plain",
  ["copying"] = "text/plain",
}

local extensions = {
  asc        = "text/plain",
  bash       = "text/x-shellscript",
  btrfs      = "application/octet-stream",
  conf       = "text/plain",
  container  = "text/plain",
  env        = "text/plain",
  fish       = "text/x-shellscript",
  go         = "text/x-go",
  hcl        = "text/plain",
  ini        = "text/plain",
  just       = "text/plain",
  kdl        = "text/plain",
  lua        = "text/x-lua",
  mk         = "text/makefile",
  nix        = "text/plain",
  service    = "text/plain",
  sh         = "text/x-shellscript",
  socket     = "application/octet-stream",
  sops       = "text/plain",
  tf         = "text/plain",
  tfvars     = "text/plain",
  toml       = "text/plain",
  yaml       = "application/yaml",
  yml        = "application/yaml",
  zsh        = "text/x-shellscript",
}

local generic = {
  ["application/octet-stream"] = true,
  ["application/x-empty"] = true,
}

-- `file.name` is not a File field; the basename lives on the Url.
-- `file.url.name` matches the official mime-ext.yazi convention.
local function ext_mime(file)
  local name = file.url.name
  if not name then
    return nil
  end
  name = name:lower()

  if filenames[name] then
    return filenames[name]
  end

  -- `%.([^.]+)$` matches the last dot-delimited token. Dotfiles with no
  -- real extension (e.g. `.bashrc`) yield "bashrc" as the ext; this is
  -- acceptable and matches yazi's own Url:ext() behaviour.
  local ext = name:match("%.([^.]+)$")
  return ext and extensions[ext] or nil
end

-- Maximum number of concurrent magika processes spawned by M:fetch.
-- Increasing this speeds up large directories at the cost of memory/CPU.
local MAX_CONCURRENT = 8

local function spawn_magika(url)
  return Command("magika")
    :arg("-i")
    :arg("--")
    :arg(tostring(url))
    :stdout(Command.PIPED)
    :stderr(Command.NULL)
    :spawn()
end

local function read_magika(child)
  local output = child:wait_with_output()
  if not output or not output.status.success then
    return nil
  end

  local mime = output.stdout:match(":%s*([%w%-%._+]+/[%w%-%._+]+)%s*$")
  if not mime or generic[mime] then
    return nil
  end

  return mime
end

function M:fetch(job)
  local updates = {}
  local state = {}   -- FetchState: boolean per file, true when a mime was assigned
  local pending = {} -- { idx = number, file = File, child = Child }

  local function assign(idx, mime)
    if mime then
      updates[job.files[idx].url] = mime
      state[idx] = true
    else
      state[idx] = false
    end
  end

  for i, file in ipairs(job.files) do
    -- Cap concurrency: when at MAX_CONCURRENT, drain the oldest spawned child.
    if #pending >= MAX_CONCURRENT then
      local entry = table.remove(pending, 1)
      assign(entry.idx, read_magika(entry.child) or ext_mime(entry.file))
    end

    local child = spawn_magika(file.url)
    if child then
      pending[#pending + 1] = { idx = i, file = file, child = child }
    else
      assign(i, ext_mime(file))
    end
  end

  -- Drain remaining spawns.
  for _, entry in ipairs(pending) do
    assign(entry.idx, read_magika(entry.child) or ext_mime(entry.file))
  end

  if next(updates) then
    ya.emit("update_mimes", { updates = updates })
  end

  return state
end

return M
