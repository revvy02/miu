--[[ VirtualList — virtualized scrolling for miu immediate-mode UI

	Port of ultimate-list's ScrollingFrame + VirtualizedListController.
	Renders only visible items for large data sets.

	Uses a dual-layer pattern matching UltimateList:
		Frame (outer container)
		├── ScrollingFrame (scroll input + scrollbar, CanvasSize set, empty)
		└── Frame (overlay, ClipsDescendants, renders items with positions adjusted by -scrollAxis)

	CanvasPosition updates are deferred in Roblox, causing flicker if items are
	direct ScrollingFrame children. The overlay avoids this.
]]

local Miu = require(script.Parent.Parent.miu)
local Instance = Miu.Instance

local Dimensions = require("./Dimensions")

-- Offset boundary cache check (port of controller:133-147).
-- Returns cached range if scroll is within boundaries, otherwise nil.
local function getCachedRange(state, scrollAxis, windowAxis, windowSize, dataLength)
	if
		state.headOffset ~= nil
		and state.headOffset <= scrollAxis
		and state.tailOffset >= windowAxis + scrollAxis
		and state.prevWindowSize == windowSize
		and state.prevDataLen == dataLength
	then
		return state.cachedHead, state.cachedTail
	end
	return nil, nil
end

-- Update offset boundary cache after computing a new range (port of controller:185-203).
local function updateCache(state, head, tail, dimensions, data, windowSize, direction, dataLength)
	if head == 0 or tail == 0 then
		state.headOffset = 0
		state.tailOffset = 0
		state.cachedHead = 0
		state.cachedTail = 0
		state.prevWindowSize = windowSize
		state.prevDataLen = dataLength
		return
	end

	local headRect = Dimensions.getUDimRect(dimensions, data[head], head, windowSize, direction)
	local tailRect = Dimensions.getUDimRect(dimensions, data[tail], tail, windowSize, direction)

	if direction == "x" then
		state.headOffset = headRect.position.X.Offset
		state.tailOffset = tailRect.position.X.Offset + tailRect.size.X.Offset
	else
		state.headOffset = headRect.position.Y.Offset
		state.tailOffset = tailRect.position.Y.Offset + tailRect.size.Y.Offset
	end

	state.cachedHead = head
	state.cachedTail = tail
	state.prevWindowSize = windowSize
	state.prevDataLen = dataLength
end

local function push(props, render)
	local data = props.data
	local dimensions = props.dimensions
	local direction = props.direction or "y"

	-- Outer container frame
	Instance.push("Frame", {
		tags = props.tags,
		id = props.id,
		Size = props.Size or UDim2.fromScale(1, 1),
		Position = props.Position,
		AnchorPoint = props.AnchorPoint,
		BackgroundTransparency = 1,
		ZIndex = props.ZIndex,
		LayoutOrder = props.LayoutOrder,
		Visible = props.Visible,
	})

	-- ScrollingFrame — scroll input + scrollbar, empty inside
	local scrollNode = Instance("ScrollingFrame", {
		id = "scroll",
		tags = props.tags,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = props.BackgroundTransparency or 1,
		BackgroundColor3 = props.BackgroundColor3,
		ScrollBarThickness = props.ScrollBarThickness,
		ScrollBarImageTransparency = props.ScrollBarImageTransparency,
		ScrollingDirection = if direction == "y" then Enum.ScrollingDirection.Y else Enum.ScrollingDirection.X,
		BorderSizePixel = 0,
	})

	-- Read scroll state from the ScrollingFrame instance
	local scrollInstance = scrollNode.instance
	local canvasPosition = if scrollInstance then scrollInstance.CanvasPosition else Vector2.zero
	local scrollAxis = if direction == "x" then canvasPosition.X else canvasPosition.Y

	-- Overlay frame — renders items here, clips descendants
	-- Size matches ScrollingFrame's AbsoluteWindowSize (viewport minus scrollbar)
	local windowSize = if scrollInstance then scrollInstance.AbsoluteWindowSize else Vector2.zero
	Instance.push("Frame", {
		id = "overlay",
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Size = UDim2.fromOffset(windowSize.X, windowSize.Y),
		ZIndex = 2,
	})

	local windowAxis = Dimensions.getDominantAxis(windowSize, direction)

	-- Set canvas size on the ScrollingFrame
	if scrollInstance then
		scrollInstance.CanvasSize = Dimensions.getCanvasSize(dimensions, data, windowSize, direction)
	end

	-- Nothing to render if no data or no viewport
	if #data == 0 or windowAxis == 0 then
		return
	end

	-- Compute visible range with offset boundary caching
	local state = Miu.peek()
	local head, tail = getCachedRange(state, scrollAxis, windowAxis, windowSize, #data)

	if head == nil then
		head, tail = Dimensions.getVisibleRange(dimensions, data, scrollAxis, windowAxis, windowSize, direction)
		updateCache(state, head, tail, dimensions, data, windowSize, direction, #data)
	end

	-- Render visible items
	head = math.max(1, head)
	tail = math.min(#data, tail)

	for i = head, tail do
		local rect = Dimensions.getUDimRect(dimensions, data[i], i, windowSize, direction)
		local adjustedPosition = Dimensions.adjustForScroll(rect.position, scrollAxis, direction)

		Instance.push("Frame", {
			id = i,
			BackgroundTransparency = 1,
			Size = rect.size,
			Position = adjustedPosition,
		})
		render(data[i], i)

		-- Auto-measure first item's content height for cachedFirstAbsoluteSize
		if i == head and dimensions._measureFirstItem then
			local itemNode = Miu.peek()
			for _, child in itemNode.children do
				if child.instance then
					local measured = if direction == "x" then child.instance.AbsoluteSize.X else child.instance.AbsoluteSize.Y
					if measured > 0 then
						dimensions.size = measured
					end
					break
				end
			end
		end

		Instance.pop()
	end
end

local function pop()
	Instance.pop() -- overlay
	Instance.pop() -- outer container
end

return setmetatable({
	push = push,
	pop = pop,
}, {
	__call = function(_, props, render)
		push(props, render)
		pop()
	end,
})
