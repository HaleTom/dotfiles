local plugin = dofile("main.lua")

local emitted = {}
local clock = 0

ya = {
	time = function()
		return clock
	end,
	emit = function(command, args)
		table.insert(emitted, { command = command, args = args })
	end,
}

local function reset(cursor, count, now)
	emitted = {}
	clock = now or 1
	cx = {
		active = {
			current = {
				cursor = cursor,
				files = {},
			},
		},
	}
	for i = 1, count do
		cx.active.current.files[i] = {}
	end
end

local function run(direction, now)
	clock = now or clock
	plugin.entry(nil, { args = { direction } })
	return emitted[#emitted]
end

local function assert_arrow(name, direction, cursor, count, now, want)
	reset(cursor, count, now)
	local event = run(direction, now)
	assert(event.command == "arrow", name .. ": command")
	assert(event.args[1] == want, name .. ": got " .. tostring(event.args[1]) .. ", want " .. tostring(want))
end

assert_arrow("tap down at bottom wraps", "down", 2, 3, 1, "next")
assert_arrow("tap down before bottom moves one", "down", 1, 3, 2, 1)
assert_arrow("tap up at top wraps", "up", 0, 3, 3, "prev")
assert_arrow("tap up after top moves one", "up", 1, 3, 4, -1)

reset(2, 3, 10)
run("down", 10)
local event = run("down", 10.05)
assert(event.args[1] == 1, "held down at bottom must not wrap")
event = run("down", 10.30)
assert(event.args[1] == "next", "tap down after previous hold must wrap")

reset(0, 3, 20)
run("up", 20)
event = run("up", 20.05)
assert(event.args[1] == -1, "held up at top must not wrap")
event = run("up", 20.30)
assert(event.args[1] == "prev", "tap up after previous hold must wrap")

print("ok")
