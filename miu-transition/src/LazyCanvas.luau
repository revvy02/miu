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
