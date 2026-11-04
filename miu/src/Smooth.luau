local DeltaTime = require("./DeltaTime")
local scope = require("./scope")

-- Framerate-independent easing toward `goal`, stored on a persistent miu node. Numbers ease
-- exponentially; any Lerp-able value (Color3, UDim2, Vector2/3, CFrame, …) eases via :Lerp with
-- the equivalent alpha (1 - e^(-rate·dt)), so every type animates identically.
--
-- `id` is optional: without one the node comes from the auto-cursor, so the value is keyed by
-- evaluation order within the enclosing scope. Pass an id whenever that order isn't fixed — a
-- conditional call, a call inside a loop, or sibling Smooth calls in one props table (fields
-- evaluate in source order, so reordering two of them would swap their state silently).
local function Smooth(goal, rate, id)
	local node = scope(id)
	if node.value == nil then
		node.value = goal
	end

	local decay = math.exp(-(rate or 12) * DeltaTime())
	if type(goal) == "number" then
		node.value = goal + (node.value - goal) * decay
	else
		node.value = (node.value :: any):Lerp(goal, 1 - decay)
	end

	return node.value
end

return Smooth
