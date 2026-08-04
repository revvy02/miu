local RunService = game:GetService("RunService")

local Miu = require("./miu")
local Portal = Miu.Portal
local Px = require("./miu_px")
local UILabs = require("./ui_labs")

-- Publish miu root to real _G so rodeo can access the live tree
-- (UI Labs sandboxes _G per-story, OriginalG is the unsandboxed one)
local realG = UILabs.Environment.OriginalG
realG._MIU_ROOT = Miu.root

-- Kill switch across module generations: UI Labs hot reloads re-require this
-- module, and a teardown race can leave a previous generation's PreRender loop
-- (and its nodes' event connections) alive — every leaked generation then
-- renders into the same target each frame, thrashing instance names/props and
-- double-firing events (one click, N generations' handlers). The registry lives
-- in the unsandboxed _G shared by every module generation in the plugin VM, so
-- a new mount can always destroy its predecessor no matter which generation
-- created it.
local cleanups = realG._MIU_STORY_CLEANUPS
if cleanups == nil then
	cleanups = {}
	realG._MIU_STORY_CLEANUPS = cleanups
end

local function MiuStory(config, render)
	return UILabs.CreateGenericStory({
		name = config.name,
		summary = config.summary,
		controls = config.controls,
	}, function(props)
		-- Any prior generation still mounted on this target dies first.
		local prior = cleanups[props.target]
		if prior ~= nil then
			prior()
		end

		local controls = props.controls

		local unsubscribe = props.subscribe(function(values)
			controls = values
		end)

		local connection = RunService.PreRender:Connect(function()
			Portal(props.target, "story", function()
				-- Stories scale to the story canvas, not the monitor
				Px.scope({ holder = props.target }, function()
					render(controls, props.target)
				end)
			end)
		end)

		local done = false
		local function cleanup()
			if done then
				return
			end
			done = true
			if cleanups[props.target] == cleanup then
				cleanups[props.target] = nil
			end
			connection:Disconnect()
			unsubscribe()
			-- Final empty pass triggers prune → unmounts all miu nodes
			Portal(props.target, "story", function() end)
		end
		cleanups[props.target] = cleanup

		return cleanup
	end)
end

return {
	MiuStory = MiuStory,
}
