local Element = require("../miu").Element
local Portal = require("../miu").Portal

local EPSILON = 0.03

--[[
	LazyCanvas - Optimization component that switches between CanvasGroup and Frame

	When groupTransparency > epsilon, children render in CanvasGroup (supports transparency)
	Otherwise, children render in Frame (more performant)

	Both containers always exist - children are portaled to the active one

	Usage:
		lazyCanvas.push("id", { groupTransparency = 0.5 })
			miu.leaf("child", "TextLabel", { Text = "Hello" })
		lazyCanvas.pop()
]]
local function push(props)
	local transparency = props.groupTransparency or 0
	local needsCanvas = transparency > EPSILON or props.groupColor and props.groupColor ~= Color3.new(1, 1, 1)

	local container = Element.push("Frame", {
		id = props.id,
		BackgroundTransparency = 1,
		Size = props.size or UDim2.fromScale(1, 1),
		AutomaticSize = props.automaticSize,
		Position = props.position,
		AnchorPoint = props.anchorPoint,
		LayoutOrder = props.layoutOrder,
		ZIndex = props.zIndex,
	})

	-- Measurement note (probe-verified): the scale-sized twins are FINE inside an
	-- auto-size chain — the engine propagates descendant size changes through
	-- them correctly. (An earlier 'circular auto-size' theory here was wrong.)
	-- The real engine rule to know: an AutomaticSize frame WITHOUT a UIListLayout
	-- measures the DEEP descendant bounding box and ignores ClipsDescendants, so
	-- content overflowing a clipped frame leaks its full extent into ancestor
	-- measurements. A UIListLayout on the auto frame — or anywhere between it and
	-- the clipped frame — switches measurement to layout content size and stops
	-- the leak. Callers animating a clipped row inside a measured Transition
	-- should put a UIListLayout in their content.
	local canvas = Element("CanvasGroup", {
		BackgroundTransparency = 1,
		GroupTransparency = transparency,
		GroupColor3 = props.groupColor or Color3.new(1, 1, 1),
		Size = UDim2.fromScale(1, 1),
	})

	local frame = Element("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
	})

	Portal.push(needsCanvas and canvas.instance or frame.instance)

	return container
end

local function pop()
	Portal.pop()
	Element.pop()
end

return setmetatable({
	push = push,
	pop = pop,
}, {
	__call = function(_, props, fn)
		local node = push(props)
		if fn then
			fn(node)
		end
		pop()
		return node
	end,
})
