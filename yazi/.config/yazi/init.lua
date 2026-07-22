-- # Fixme: not working at 2026-07-07
-- # https://www.perplexity.ai/search/aadfbf8e-429d-4188-b4f7-e363d4bbda8b#2
-- # Should be called from ~/.config/yazi/keymap.toml  mgr.linemode
function Linemode:stat()
    local cha = self._file.cha

    -- cha:perm() returns the formatted permission string (e.g. "rwxr-xr-x") since v0.4.0
    local perm = cha:perm() or "?"

    -- size
    local size = self._file:size()
    size = size and ya.readable_size(size) or "-"

    -- mtime
    local time = math.floor(cha.mtime or 0)
    if time == 0 then
        time = ""
    elseif os.date("%Y", time) == os.date("%Y") then
        time = os.date("%b %d %H:%M", time)
    else
        time = os.date("%b %d %Y", time)
    end

    -- owner / group (uid/gid resolved to names)
    local owner = ya.user_name and ya.user_name(cha.uid) or tostring(cha.uid)
    local group = ya.group_name and ya.group_name(cha.gid) or tostring(cha.gid)

    return string.format("%s %s:%s %6s %s", perm, owner, group, size, time)
end
