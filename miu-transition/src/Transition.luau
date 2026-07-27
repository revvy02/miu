local Element = require("../miu").Element
local Miu = require("../miu")
local DeltaTime = Miu.DeltaTime

local Float = require("./Float")
local LazyCanvas = require("./LazyCanvas")
local cubicOut = require("./utils/cubicOut")
local expTransition = require("./utils/expTransition")

--[[
	Transition - Animated show/hide with position and transparency

	Composes Float + LazyCanvas. Uses a Miu node to hold animation state,
	then passes computed transforms to Float as props.

	Functional: Transition(props, fn). fn(visible) renders the content; `visible` is false once
	fully hidden so the caller can skip its children. The call also returns `visible`.

	Note: Transform animations (widthTransform/heightTransform) clip content
	because LazyCanvas is inside Float's content frame, which fills the
	transformed container. To fix, content would need to render twice:
	1. Inside content frame (invisible) — drives AutomaticSize measurement
	2. Inside renderFloatingChildren → LazyCanvas — visible at untransformed size

	Presets: `preset` names a common animation shape; any explicitly passed
	prop overrides the preset's value (explicit prop > preset > default).
		slideDiagonal  - diagonal slide + fade (same as the built-in defaults)
		slideDown      - vertical reveal in place + fade (dropdowns, panels)
		fade           - fade in place, no motion (overlays)
		collapseHeight - fade + height shrink, no slide (list rows, collapsibles)
		collapseWidth  - fade + width shrink, no slide
		collapseBoth   - fade + both-axis shrink, no slide (2D grids)

	Usage:
		Transition({ id = "id", show = true, size = UDim2.fromScale(1, 1) }, function(visible)
			if visible then
				Element("TextLabel", { Text = "Hello" })
			end
		end)
]]

local CENTER = UDim2.fromScale(0.5, 0.5)
local DECAY = 12
local IN_DIRECTION = UDim2.fromScale(-1.5, -0.5)
local OUT_DIRECTION = UDim2.fromScale(1.5, -0.5)

local PRESETS = {
	slideDiagonal = table.freeze({
		animateDirection = true,
		animateInDirection = IN_DIRECTION,
		animateOutDirection = OUT_DIRECTION,
		animateTransparency = true,
	}),
	slideDown = table.freeze({
		animateDirection = true,
		animateInDirection = UDim2.fromScale(0.5, 0),
		animateOutDirection = UDim2.fromScale(0.5, 0),
		animateTransparency = true,
	}),
	fade = table.freeze({
		animateDirection = false,
		animateTransparency = true,
	}),
	collapseHeight = table.freeze({
		animateDirection = false,
		animateTransparency = true,
		animateHeightTransform = true,
	}),
	collapseWidth = table.freeze({
		animateDirection = false,
		animateTransparency = true,
		animateWidthTransform = true,
	}),
	collapseBoth = table.freeze({
		animateDirection = false,
		animateTransparency = true,
		animateWidthTransform = true,
		animateHeightTransform = true,
	}),
}
local NO_PRESET = table.freeze({})

-- Precedence: explicit prop > preset value > built-in default. Booleans need
-- the nil checks — an explicit false must beat a preset's true.
local function resolve(explicit, presetValue, default)
	if explicit ~= nil then
		return explicit
	end
	if presetValue ~= nil then
		return presetValue
	end
	return default
end

local function Transition(props, fn)
	local preset = if props.preset ~= nil then PRESETS[props.preset] or error(`Transition: unknown preset "{props.preset}"`, 2) else NO_PRESET

	local dt = DeltaTime()
	local show = props.show
	local decay = resolve(props.decay, preset.decay, DECAY)
	local animateDirection = resolve(props.animateDirection, preset.animateDirection, true)
	local animateInDirection = resolve(props.animateInDirection, preset.animateInDirection, IN_DIRECTION)
	local animateOutDirection = resolve(props.animateOutDirection, preset.animateOutDirection, OUT_DIRECTION)
	local animateTransparency = resolve(props.animateTransparency, preset.animateTransparency, true)
	local animateWidthTransform = resolve(props.animateWidthTransform, preset.animateWidthTransform, false)
	local animateHeightTransform = resolve(props.animateHeightTransform, preset.animateHeightTransform, false)
	local mapTransparency = resolve(props.mapTransparency, preset.mapTransparency, cubicOut)

	local state = Miu(props.id)

	if state.alpha == nil then
		state.alpha = 1 --show and 1 or 0
		state.targetPosition = show and animateInDirection or animateOutDirection
	end

	if show and state.alpha >= 1 then
		state.targetPosition = animateInDirection
	end

	local targetAlpha = show and 0 or 1
	local targetPosition = if show then (props.contentPosition or CENTER) else animateOutDirection
	local factor = 1 - math.exp(-decay * dt)

	state.alpha = expTransition(state.alpha, targetAlpha, decay, dt)
	state.targetPosition = state.targetPosition:Lerp(targetPosition, factor)

	local baseTransparency = props.groupTransparency or 0
	local animTransparency = animateTransparency and mapTransparency(state.alpha) or 0
	local groupTransparency = math.max(baseTransparency, animTransparency)

	-- Wrap renderFloatingChildren in an oversized LazyCanvas so floating
	-- children (shadows) fade with the transition without being clipped.
	-- AutomaticSize=XY keeps the oversize from bubbling into ancestor
	-- AutomaticSize cascades; without it, every wrapping `auto-size` parent
	-- measures the 3x bounds instead of the actual shadow content.
	local renderFloatingChildren = props.renderFloatingChildren
	if renderFloatingChildren then
		renderFloatingChildren = function()
			LazyCanvas.push({
				groupTransparency = groupTransparency,
				groupColor = props.groupColor,
				size = UDim2.fromScale(3, 3),
				automaticSize = Enum.AutomaticSize.XY,
				position = UDim2.fromScale(0.5, 0.5),
				anchorPoint = Vector2.new(0.5, 0.5),
			})
			Element.push("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1 / 3, 1 / 3),
				Position = UDim2.fromScale(0.5, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5),
			})
			props.renderFloatingChildren()
			Element.pop()
			LazyCanvas.pop()
		end
	end

	local visible = state.alpha < 1

	Float({
		widthTransform = props.widthTransform or animateWidthTransform and (1 - state.alpha) or 1,
		heightTransform = props.heightTransform or animateHeightTransform and (1 - state.alpha) or 1,

		size = props.size,
		automaticSize = props.automaticSize,
		position = props.position,
		anchorPoint = props.anchorPoint,
		rotation = props.rotation,
		backgroundColor3 = props.backgroundColor3,
		backgroundTransparency = props.backgroundTransparency or 1,
		clipsDescendants = props.clipsDescendants,
		visible = props.visible,
		zIndex = props.zIndex,
		layoutOrder = props.layoutOrder,
		tags = props.tags,
		contentAnchorPoint = Vector2.new(0.5, 0.5),
		contentPosition = animateDirection and state.targetPosition or props.contentPosition or nil,
		renderFloatingChildren = renderFloatingChildren,
	}, function()
		LazyCanvas.push({
			groupTransparency = groupTransparency,
			groupColor = props.groupColor,
			size = UDim2.fromScale(1, 1),
		})
		if fn then
			fn(visible)
		end
		LazyCanvas.pop()
	end)

	return visible
end

return Transition
