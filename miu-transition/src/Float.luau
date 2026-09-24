local Element = require("../miu").Element
local Portal = require("../miu").Portal

local PIXEL_BIAS = 0.975 -- helps with the 1 pixel stuttering when animations converge, as UDim2 offset rounds to nearest pixel

--[[
	Float - Layout component for animated content positioning

	Features:
	- Content positioned relative to container (contentPosition/contentAnchorPoint)
	- Width/height transforms for scale animations
	- AutomaticSize support (container derives size from content)

	Functional: Float(props, fn) renders fn's children into the content frame, THEN measures.
	Measuring after the children exist is the whole point — reading AbsoluteSize flushes layout
	synchronously, so the container gets *this* frame's true content size (no one-frame lag that
	the old push/pop form had from measuring before the children rendered).

	Usage:
		Float({
			id = "id",
			size = UDim2.fromScale(1, 0),
			automaticSize = Enum.AutomaticSize.Y,
			contentPosition = UDim2.fromScale(0.5, 0.5),
			widthTransform = 0.5, -- scale width offset by 0.5
		}, function()
			Element("TextLabel", { Text = "Hello" })
		end)
]]

local function applyTransform(size: UDim2, widthTransform, heightTransform): UDim2
	local x, y = size.X, size.Y
	local xo, yo = x.Offset, y.Offset

	-- UDim transforms: affine on offset only, scale passes through
	if typeof(widthTransform) == "UDim" then
		local newXOffset = xo * widthTransform.Scale + widthTransform.Offset
		local newYOffset = if typeof(heightTransform) == "UDim"
			then yo * heightTransform.Scale + heightTransform.Offset
			else yo * heightTransform
		local newYScale = if typeof(heightTransform) == "UDim" then y.Scale else y.Scale * heightTransform
		return UDim2.new(x.Scale, newXOffset + PIXEL_BIAS, newYScale, newYOffset + PIXEL_BIAS)
	elseif typeof(heightTransform) == "UDim" then
		local newYOffset = yo * heightTransform.Scale + heightTransform.Offset
		return UDim2.new(x.Scale * widthTransform, xo * widthTransform + PIXEL_BIAS, y.Scale, newYOffset + PIXEL_BIAS)
	end

	-- Numeric transforms: multiply both scale and offset. The bias scales with the
	-- transform so a zero transform is EXACTLY zero: a flat bias leaves a collapsed
	-- row ~1px tall until its removal lifetime expires, and that pixel popping out
	-- at unmount reads as a one-frame flicker at the end of the exit animation.
	return UDim2.new(
		x.Scale * widthTransform,
		xo * widthTransform + PIXEL_BIAS * widthTransform,
		y.Scale * heightTransform,
		yo * heightTransform + PIXEL_BIAS * heightTransform
	)
end

local function computeContentSize(size: UDim2, automaticSize: Enum.AutomaticSize?): UDim2
	local sx, sy = size.X, size.Y

	if automaticSize == Enum.AutomaticSize.Y then
		return UDim2.new(sx.Scale, sx.Offset, 0, sy.Offset)
	elseif automaticSize == Enum.AutomaticSize.X then
		return UDim2.new(0, sx.Offset, sy.Scale, sy.Offset)
	elseif automaticSize == Enum.AutomaticSize.XY then
		return UDim2.fromOffset(sx.Offset, sy.Offset)
	else
		return UDim2.fromScale(1, 1)
	end
end

local function computeContainerSize(
	size: UDim2,
	contentAbsoluteSize: Vector2,
	automaticSize: Enum.AutomaticSize?
): UDim2
	if automaticSize == Enum.AutomaticSize.Y then
		return UDim2.new(size.X.Scale, size.X.Offset, 0, contentAbsoluteSize.Y)
	elseif automaticSize == Enum.AutomaticSize.X then
		return UDim2.new(0, contentAbsoluteSize.X, size.Y.Scale, size.Y.Offset)
	elseif automaticSize == Enum.AutomaticSize.XY then
		return UDim2.fromOffset(contentAbsoluteSize.X, contentAbsoluteSize.Y)
	else
		return size
	end
end

local function Float(props, renderChildren)
	local size = props.size or UDim2.new()
	local automaticSize = props.automaticSize
	local contentPosition = props.contentPosition or UDim2.fromScale(0.5, 0.5)
	local contentAnchorPoint = props.contentAnchorPoint or Vector2.new(0.5, 0.5)
	local widthTransform = props.widthTransform or 1
	local heightTransform = props.heightTransform or 1

	return Element("Frame", {
		id = props.id,
		BackgroundTransparency = props.backgroundTransparency or 1,
		BackgroundColor3 = props.backgroundColor3,
		Position = props.position,
		AnchorPoint = props.anchorPoint,
		Rotation = props.rotation,
		ClipsDescendants = props.clipsDescendants,
		Visible = props.visible,
		ZIndex = props.zIndex,
		LayoutOrder = props.layoutOrder,
	}, function(container)
		local content = Element("Frame", {
			tags = props.tags,
			id = "Content",
			BackgroundTransparency = 1,
			AutomaticSize = automaticSize,
			AnchorPoint = contentAnchorPoint,
			Position = contentPosition,
			Size = computeContentSize(size, automaticSize),
			ZIndex = props.contentZIndex or 2,
		}, renderChildren)
		-- Render the content's children, THEN measure. Reading AbsoluteSize flushes layout
		-- synchronously, so with the children already in place this is the current frame's
		-- true content size.

		-- AbsoluteSize is post-UIScale while Size offsets are pre-scale inputs, so any
		-- measured absolute value must be divided by the accumulated ancestor scale before
		-- being written back — otherwise a Float under UIScale s renders measured content
		-- at s^2. The ruler derives that factor empirically: a known 100px offset input
		-- read back through the render pipeline. It sits at container level on purpose: a
		-- UIScale the caller renders inside Content (press feedback) is genuinely part of
		-- the measured content size and is NOT divided out. Only the paths converting
		-- absolute pixels to offsets need the factor, so the ruler only exists for them.
		-- The analytical fix is scoped px (miu-px factor scopes): when all px quantities
		-- route through px() and scaling is a scope factor, the factor is known without
		-- measurement — Float would take it as a prop and the ruler becomes redundant
		-- (or a cross-check assertion).
		-- The ruler sits left of the origin: AutomaticSize ancestors measure the deep
		-- descendant bounding box but ignore extent left of/above the origin, so at (0, 0)
		-- its 100px width padded any narrower auto-sized list row (without a UIListLayout
		-- between) to 100px, with the content stuck on the left.
		local derivedScale = 1
		if automaticSize or props.renderFloatingChildren then
			local ruler = Element("Frame", {
				id = "UIScaleDeriver",
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(-100, 0),
				Size = UDim2.fromOffset(100, 0),
				ZIndex = -1,
			})
			derivedScale = ruler.instance.AbsoluteSize.X / 100
		end

		-- Known limitation: wrapped AutomaticSize text under an auto Float measures only
		-- the lines that fit the container's current height (engine clamps wrapped-text
		-- auto measure to the constraining ancestor), so it locks at one line.
		-- Workaround (verified): RichText = true — rich text measures through an
		-- unclamped path and reports the full wrapped height at any ancestor height.
		-- Otherwise give wrapped text a fixed-height row.
		-- The corrected measurement is rounded to design-space integers: rendered
		-- sizes are quantized to device pixels, so the raw division yields 24±ε that
		-- wanders across pixel-rounding boundaries while an animating ancestor scale
		-- converges (its exponential tail changes sub-pixel for seconds) — and with
		-- PIXEL_BIAS parked next to a boundary, the rows visibly vibrate. Authored
		-- content is integer design px; snapping to it removes the noise.
		local contentAbsoluteSize
		if automaticSize and content.instance and derivedScale > 0 then
			local measured = content.instance.AbsoluteSize / derivedScale
			contentAbsoluteSize = Vector2.new(math.round(measured.X), math.round(measured.Y))
		else
			contentAbsoluteSize = Vector2.new(size.X.Offset, size.Y.Offset)
		end
		local containerSize = computeContainerSize(size, contentAbsoluteSize, automaticSize)

		if props.renderFloatingChildren then
			-- Untransformed size for renderFloatingChildren, in pre-scale offset units:
			-- the parent's AbsoluteSize is post-scale, so it gets the same division.
			local parentSize = if container.instance.Parent ~= nil and derivedScale > 0
				then container.instance.Parent.AbsoluteSize / derivedScale
				else Vector2.zero
			local untransformedSize = Vector2.new(
				containerSize.X.Scale * parentSize.X + containerSize.X.Offset,
				containerSize.Y.Scale * parentSize.Y + containerSize.Y.Offset
			)

			Element("Frame", {
				id = "FloatingChildren",
				BackgroundTransparency = 1,
				Size = UDim2.fromOffset(untransformedSize.X, untransformedSize.Y),
				Position = contentPosition,
				AnchorPoint = contentAnchorPoint,
				ZIndex = 1,
			}, props.renderFloatingChildren)
		end

		container.instance.Size = applyTransform(containerSize, widthTransform, heightTransform)
	end) :: any
end

return Float
