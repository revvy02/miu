local RunService = game:GetService("RunService")

local Miu = require("./miu")
local Portal = Miu.Portal
local PxCanvas = require("./miu_px").PxCanvas
local UILabs = require("./ui_labs")

-- Publish miu root to real _G so rodeo can access the live tree
-- (UI Labs sandboxes _G per-story, OriginalG is the unsandboxed one)
local realG = UILabs.Environment.OriginalG
realG._MIU_ROOT = Miu.root

local function MiuStory(config, render)
	return UILabs.CreateGenericStory({
		name = config.name,
		summary = config.summary,
		controls = config.controls,
	}, function(props)
		local controls = props.controls

		local unsubscribe = props.subscribe(function(values)
			controls = values
		end)

		local connection = RunService.PreRender:Connect(function()
			Portal(props.target, "story", function()
				-- Stories scale to the story canvas, not the monitor
				PxCanvas({ holder = props.target }, function()
					render(controls, props.target)
				end)
			end)
		end)

		return function()
			connection:Disconnect()
			unsubscribe()
			-- Final empty pass triggers prune → unmounts all miu nodes
			Portal(props.target, "story", function() end)
		end
	end)
end

return {
	MiuStory = MiuStory,
}
