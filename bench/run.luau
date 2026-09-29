--[[
	Benchmarks each fixture's walk: its render run through a Portal into its own ScreenGui, over and
	over in a tight loop, so what's timed is miu's synchronous work (walk, diff, prune, engine reads
	and writes) with no frames in between.

	Per fixture: median µs per walk and per node, a rough KB allocated per walk (gcinfo deltas;
	samples where the GC ran are dropped), and a check that the ScreenGui's instance count at the
	end still equals the count after the warmup (and `expectedInstances` when the fixture states
	it), so a broken optimization fails instead of looking fast. The count is taken after the
	warmup because Transitions only show their content once real time has passed.

	Run through `mise run bench` (see bench/README.md). Args: [--baseline <results.json>]
]]
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local fs = require("@rodeo/fs")
local process = require("@rodeo/process")
local stream = require("@rodeo/stream")

local Portal = require("./pkgs").miu.Portal

local FIXTURES = {
	require("./fixtures/flat"),
	require("./fixtures/nested"),
	require("./fixtures/tagged"),
	require("./fixtures/stylesheet"),
	require("./fixtures/changing"),
	require("./fixtures/churn"),
	require("./fixtures/transitions"),
}

local WARMUP = 50
local SAMPLES = 20
local WALKS = 50

local baselinePath
for i, arg in process.args do
	if arg == "--baseline" then
		baselinePath = process.args[i + 1]
	end
end

local function median(values)
	if #values == 0 then
		return nil
	end
	local sorted = table.clone(values)
	table.sort(sorted)
	local mid = #sorted // 2
	return if #sorted % 2 == 1 then sorted[mid + 1] else (sorted[mid] + sorted[mid + 1]) / 2
end

local function countNodes(node)
	local n = 0
	for _, child in node.children do
		n += 1 + countNodes(child)
	end
	return n
end

local function git(args)
	local result = process.run({ "git", table.unpack(args) })
	return string.gsub(result.stdout or result.out or "", "%s+$", "")
end

local results = {
	rev = git({ "rev-parse", "--short", "HEAD" }),
	dirty = git({ "status", "--porcelain", "--", "miu", "miu-wind", "miu-transition", "miu-px", "bench" }) ~= "",
	walksPerSample = WALKS,
	samples = SAMPLES,
	fixtures = {},
	order = {},
}

local failures = {}
for _, fixture in FIXTURES do
	local gui = Instance.new("ScreenGui")
	gui.Name = "bench-" .. fixture.name
	gui.Parent = StarterGui

	local walk = 0
	local root
	local function step()
		walk += 1
		root = Portal(gui, "root", function()
			fixture.render(walk)
		end)
	end

	for _ = 1, WARMUP do
		step()
	end
	local mounted = #gui:GetDescendants()
	local nodes = countNodes(root)

	local us, kb = {}, {}
	for _ = 1, SAMPLES do
		local kb0 = gcinfo()
		local t0 = os.clock()
		for _ = 1, WALKS do
			step()
		end
		local seconds = os.clock() - t0
		local grown = gcinfo() - kb0
		table.insert(us, seconds / WALKS * 1e6)
		if grown >= 0 then
			table.insert(kb, grown / WALKS)
		end
		task.wait() -- stay under the script timeout; lets the engine run between samples
	end

	local final = #gui:GetDescendants()
	if final ~= mounted then
		table.insert(failures, `{fixture.name}: {mounted} instances after the warmup, {final} at the end`)
	end
	if fixture.expectedInstances and mounted ~= fixture.expectedInstances then
		table.insert(failures, `{fixture.name}: {mounted} instances, expected {fixture.expectedInstances}`)
	end

	local usPerWalk = median(us)
	results.fixtures[fixture.name] = {
		summary = fixture.summary,
		usPerWalk = usPerWalk,
		usPerNode = usPerWalk / nodes,
		nodes = nodes,
		instances = mounted,
		kbPerWalk = median(kb),
		samplesUs = us,
	}
	table.insert(results.order, fixture.name)

	Portal(gui, "root", function() end)
	gui:Destroy()
	task.wait()
end

local baseline
if baselinePath then
	local handle = fs.open(baselinePath, "r")
	baseline = HttpService:JSONDecode(stream.read(handle))
	stream.close(handle)
end

-- One print: rodeo streams separate prints and can deliver them out of order
local lines = {
	string.format("miu bench @ %s%s", results.rev, if results.dirty then " (dirty)" else ""),
	string.format("%-12s %10s %9s %7s %9s  %s", "fixture", "µs/walk", "µs/node", "nodes", "KB/walk", if baseline then "vs baseline" else ""),
}
for _, name in results.order do
	local r = results.fixtures[name]
	local delta = ""
	local before = baseline and baseline.fixtures[name]
	if before then
		delta = string.format("%+.1f%% (%.1f µs)", (r.usPerWalk / before.usPerWalk - 1) * 100, before.usPerWalk)
	end
	table.insert(
		lines,
		string.format(
			"%-12s %10.1f %9.3f %7d %9s  %s",
			name,
			r.usPerWalk,
			r.usPerNode,
			r.nodes,
			if r.kbPerWalk then string.format("%.2f", r.kbPerWalk) else "-",
			delta
		)
	)
end
print(table.concat(lines, "\n"))

if #failures > 0 then
	error("instance checks failed:\n  " .. table.concat(failures, "\n  "))
end
return results
