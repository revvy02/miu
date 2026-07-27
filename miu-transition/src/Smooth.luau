local Miu = require("../miu")
local DeltaTime = Miu.DeltaTime

local expLerp = require("./utils/expLerp")

-- Framerate-independent easing toward `goal`, stored on a persistent miu node. Numbers ease via
-- expLerp; any Lerp-able value (Color3, UDim2, Vector2/3, CFrame, …) eases via :Lerp with the
-- equivalent alpha (1 - e^(-rate·dt)), so every type animates identically.
local function Smooth(goal, rate)
	local node = Miu()
	if node.value == nil then
		node.value = goal
	end

	local dt = DeltaTime()
	if type(goal) == "number" then
		node.value = expLerp(node.value, goal, rate or 12, dt)
	else
		node.value = (node.value :: any):Lerp(goal, 1 - math.exp(-(rate or 12) * dt))
	end

	return node.value
end

return Smooth
