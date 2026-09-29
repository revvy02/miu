--[[
	Benchmarks each fixture's walk: its render run through a Portal into its own ScreenGui, over and
	over in a tight loop, so what's timed is miu's synchronous work (walk, diff, prune, engine reads
	and writes) with no frames in between.

	Per fixture: median µs per walk and per node, a rough KB allocated per walk (gcinfo deltas;
	samples where the GC ran are dropped), and a check that the ScreenGui's instance count at the
	end still equals the count after the warmup (and `expectedInstances` when the fixture states
	it), so a broken optimization fails instead of looking fast. The count is taken after the
	warmup because Transitions only show their content once real time has passed; a fixture's
	`warmupSeconds` extends the warmup until they've settled. A fixture's `check(gui)` runs after
	each sample, outside the timing, and fails the run with the message it returns.

	A/B mode (--ab <dir>) renders every fixture against two independent copies of the packages in
	one session: the candidate from the working tree and the baseline from <dir>, a git ref's
	package sources laid out like the repo. Both are imported at runtime the same way, so neither
	gains from how its modules were created (the rojo-built copy measured a few percent faster than
	an imported one of the same code). The two alternate on every walk, each walk timed on its
	own: anything that slows Studio for a stretch (focus changes, App Nap, other load) hits both
	sides alike, and the garbage collector's work, which runs in a cycle of a few hundred walks,
	lands on each side in proportion to what it allocates. (Alternating whole 50-walk samples
	lined up with that cycle and handed one side most of the GC-free samples: identical code
	measured 3-6% apart.) Each round is ROUND_PAIRS walk pairs; the change is the median of the
	per-round ratios.

	Run through `mise run bench` or `mise run bench-ab` (see bench/README.md).
	Args: --baseline <results.json> for single mode, or --ab <dir> --ab-ref <name>
	(and optionally --ab-retained-scope <dir>) for A/B mode.
]]
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local fs = require("@rodeo/fs")
local process = require("@rodeo/process")
local stream = require("@rodeo/stream")

local loadPkgs = require("./pkgs")

local FACTORIES = {
	require("./fixtures/flat"),
	require("./fixtures/nested"),
	require("./fixtures/tagged"),
	require("./fixtures/stylesheet"),
	require("./fixtures/changing"),
	require("./fixtures/churn"),
	require("./fixtures/transitions"),
	require("./fixtures/transitionsSettled"),
	require("./fixtures/nestedFloats"),
}

local WARMUP = 50
local SAMPLES = 20
local WALKS = 50
local ROUND_PAIRS = 100 -- A/B mode: walk pairs per round (SAMPLES rounds)

local args = {}
for i, arg in process.args do
	if string.sub(arg, 1, 2) == "--" then
		args[string.sub(arg, 3)] = process.args[i + 1]
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

local function git(gitArgs)
	local result = process.run({ "git", table.unpack(gitArgs) })
	return string.gsub(result.stdout or result.out or "", "%s+$", "")
end

local function readFile(path)
	local handle = fs.open(path, "r")
	local source = stream.read(handle)
	stream.close(handle)
	return source
end

-- The instance tree rojo builds from a package's src directory: a directory with init.luau is a
-- ModuleScript holding it, one without is a Folder, and every other .luau file is a child
-- ModuleScript. Stories are skipped (they require UI Labs, which the baseline doesn't carry).
local function importDir(path: string, name: string): Instance
	local entries = fs.listdir(path)
	local root
	if fs.exists(path .. "/init.luau") then
		root = Instance.new("ModuleScript")
		root.Source = readFile(path .. "/init.luau")
	else
		root = Instance.new("Folder")
	end
	root.Name = name
	for _, entry in entries do
		local full = `{path}/{entry.name}`
		if entry.type == "dir" then
			importDir(full, entry.name).Parent = root
		elseif entry.name ~= "init.luau" and string.match(entry.name, "%.luau$") and not string.match(entry.name, "%.story%.luau$") then
			local module = Instance.new("ModuleScript")
			module.Name = string.gsub(entry.name, "%.luau$", "")
			module.Source = readFile(full)
			module.Parent = root
		end
	end
	return root
end

-- A package set imported from a checkout's sources (root holds miu/src, miu-wind/src, ...), under
-- the require aliases dev.project.json uses
local function importSet(name: string, root: string, retainedScopeDir: string): Instance
	local folder = Instance.new("Folder")
	folder.Name = name
	for alias, src in { miu = "miu/src", miu_px = "miu-px/src", miu_transition = "miu-transition/src", miu_wind = "miu-wind/src" } do
		importDir(`{root}/{src}`, alias).Parent = folder
	end
	importDir(retainedScopeDir, "retained_scope").Parent = folder
	folder.Parent = ReplicatedStorage
	return folder
end

-- retained-scope's source as the dev place mounts it
local function devRetainedScope(): string
	local project = HttpService:JSONDecode(readFile("dev.project.json"))
	return project.tree.ReplicatedStorage.pkgs.retained_scope["$path"]
end

-- One fixture rendered with one package set, into its own ScreenGui
local function mount(factory, pkgs, tag: string)
	local fixture = factory(pkgs)
	local gui = Instance.new("ScreenGui")
	gui.Name = `bench-{fixture.name}-{tag}`
	gui.Parent = StarterGui
	local Portal = pkgs.miu.Portal
	local run = { fixture = fixture, gui = gui, walk = 0, label = fixture.name .. (if tag == "" then "" else ` ({tag})`) }

	function run.step()
		run.walk += 1
		run.root = Portal(gui, "root", function()
			fixture.render(run.walk)
		end)
	end
	-- µs per walk over WALKS walks
	function run.sample(): number
		local t0 = os.clock()
		for _ = 1, WALKS do
			run.step()
		end
		return (os.clock() - t0) / WALKS * 1e6
	end
	function run.unmount()
		Portal(gui, "root", function() end)
		gui:Destroy()
	end
	return run
end

-- Warms every run together, then records their instance and node counts
local function warm(runs)
	for _ = 1, WARMUP do
		for _, run in runs do
			run.step()
		end
	end
	-- Fixtures that ease by real time (Transitions) keep walking, a frame at a time, until settled
	local seconds = runs[1].fixture.warmupSeconds
	if seconds then
		local t0 = os.clock()
		while os.clock() - t0 < seconds do
			for _, run in runs do
				run.step()
			end
			task.wait()
		end
	end
	for _, run in runs do
		run.mounted = #run.gui:GetDescendants()
		run.nodes = countNodes(run.root)
	end
end

local failures = {}
local function check(run)
	local problem = run.fixture.check and run.fixture.check(run.gui)
	if problem and not run.checkFailed then
		run.checkFailed = true
		table.insert(failures, `{run.label}: {problem}`)
	end
end
local function finish(run)
	local final = #run.gui:GetDescendants()
	if final ~= run.mounted then
		table.insert(failures, `{run.label}: {run.mounted} instances after the warmup, {final} at the end`)
	end
	local expected = run.fixture.expectedInstances
	if expected and run.mounted ~= expected then
		table.insert(failures, `{run.label}: {run.mounted} instances, expected {expected}`)
	end
	run.unmount()
end

local results = {
	rev = git({ "rev-parse", "--short", "HEAD" }),
	dirty = git({ "status", "--porcelain", "--", "miu", "miu-wind", "miu-transition", "miu-px", "bench" }) ~= "",
	walksPerSample = WALKS,
	roundPairs = ROUND_PAIRS,
	samples = SAMPLES,
	fixtures = {},
	order = {},
}
local lines = {}

if args.ab then
	local retainedScope = devRetainedScope()
	local candidate = loadPkgs(importSet("pkgsA", ".", retainedScope))
	local baseline = loadPkgs(importSet("pkgsB", args.ab, args["ab-retained-scope"] or retainedScope))
	results.mode = "ab"
	results.abRef = args["ab-ref"]

	for _, factory in FACTORIES do
		local cand = mount(factory, candidate, "candidate")
		local base = mount(factory, baseline, "baseline")
		warm({ cand, base })

		local usCand, usBase, ratios = {}, {}, {}
		for _ = 1, SAMPLES do
			local candSeconds, baseSeconds = 0, 0
			for pair = 1, ROUND_PAIRS do
				-- Whichever side walks second follows the other's garbage, so the order alternates
				local t0 = os.clock()
				if pair % 2 == 1 then
					cand.step()
					local t1 = os.clock()
					base.step()
					candSeconds += t1 - t0
					baseSeconds += os.clock() - t1
				else
					base.step()
					local t1 = os.clock()
					cand.step()
					baseSeconds += t1 - t0
					candSeconds += os.clock() - t1
				end
			end
			local c, b = candSeconds / ROUND_PAIRS * 1e6, baseSeconds / ROUND_PAIRS * 1e6
			table.insert(usCand, c)
			table.insert(usBase, b)
			table.insert(ratios, c / b)
			check(cand)
			check(base)
			task.wait()
		end
		finish(cand)
		finish(base)

		local name = cand.fixture.name
		results.fixtures[name] = {
			summary = cand.fixture.summary,
			change = median(ratios) - 1,
			candidate = { usPerWalk = median(usCand), minUs = math.min(table.unpack(usCand)), nodes = cand.nodes, samplesUs = usCand },
			baseline = { usPerWalk = median(usBase), minUs = math.min(table.unpack(usBase)), nodes = base.nodes, samplesUs = usBase },
		}
		table.insert(results.order, name)
		task.wait()
	end

	table.insert(
		lines,
		string.format(
			"miu bench A/B: candidate %s%s vs baseline %s, walks alternating, %d rounds of %d pairs",
			results.rev,
			if results.dirty then " (dirty)" else "",
			tostring(results.abRef),
			SAMPLES,
			ROUND_PAIRS
		)
	)
	table.insert(lines, string.format("%-20s %12s %13s %8s  %s", "fixture", "baseline µs", "candidate µs", "change", "fastest round µs (baseline -> candidate)"))
	for _, name in results.order do
		local r = results.fixtures[name]
		table.insert(
			lines,
			string.format(
				"%-20s %12.1f %13.1f %+7.1f%%  %.1f -> %.1f",
				name,
				r.baseline.usPerWalk,
				r.candidate.usPerWalk,
				r.change * 100,
				r.baseline.minUs,
				r.candidate.minUs
			)
		)
	end
else
	local candidate = loadPkgs(ReplicatedStorage:FindFirstChild("pkgs") :: Instance)
	for _, factory in FACTORIES do
		local run = mount(factory, candidate, "")
		warm({ run })

		local us, kb = {}, {}
		for _ = 1, SAMPLES do
			local kb0 = gcinfo()
			table.insert(us, run.sample())
			local grown = gcinfo() - kb0
			if grown >= 0 then
				table.insert(kb, grown / WALKS)
			end
			check(run)
			task.wait() -- stay under the script timeout; lets the engine run between samples
		end
		finish(run)

		local usPerWalk = median(us)
		results.fixtures[run.fixture.name] = {
			summary = run.fixture.summary,
			usPerWalk = usPerWalk,
			usPerNode = usPerWalk / run.nodes,
			nodes = run.nodes,
			instances = run.mounted,
			kbPerWalk = median(kb),
			samplesUs = us,
		}
		table.insert(results.order, run.fixture.name)
		task.wait()
	end

	local baseline
	if args.baseline then
		baseline = HttpService:JSONDecode(readFile(args.baseline))
	end
	table.insert(lines, string.format("miu bench @ %s%s", results.rev, if results.dirty then " (dirty)" else ""))
	table.insert(
		lines,
		string.format("%-12s %10s %9s %7s %9s  %s", "fixture", "µs/walk", "µs/node", "nodes", "KB/walk", if baseline then "vs baseline" else "")
	)
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
end

-- One print: rodeo streams separate prints and can deliver them out of order
print(table.concat(lines, "\n"))

if #failures > 0 then
	error("checks failed:\n  " .. table.concat(failures, "\n  "))
end
return results
