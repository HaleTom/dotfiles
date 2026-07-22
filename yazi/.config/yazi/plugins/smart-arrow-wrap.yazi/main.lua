--- @sync entry

local M = {}

local REPEAT_THRESHOLD = 0.16
local last = { up = nil, down = nil }

local function is_repeat(direction, now)
	local previous = last[direction]
	last[direction] = now
	return previous ~= nil and now - previous < REPEAT_THRESHOLD
end

function M:entry(job)
	local direction = job.args[1]
	local current = cx.active.current
	local count = #current.files
	if count == 0 then
		return
	end

	local cursor = current.cursor
	local repeated = is_repeat(direction, ya.time())

	if direction == "up" then
		ya.emit("arrow", { repeated and -1 or cursor == 0 and "prev" or -1 })
	elseif direction == "down" then
		ya.emit("arrow", { repeated and 1 or cursor >= count - 1 and "next" or 1 })
	end
end

return M
