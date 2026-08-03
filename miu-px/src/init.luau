local Context = require("./miu").Context
local monotoneSpline = require("@self/spline")

local camera = workspace.CurrentCamera

export type Curve = (Vector2) -> number

export type Config = {
	holder: GuiObject?,
	curve: Curve?,
	scale: number?,
	factor: number?,
}

-- A curve maps a container size to a scale factor, keyed off the smaller
-- axis — the dimension that constrains text and touch-target size. Viewport
-- sizes are device-independent units, so small min-axis means physically
-- small screen; the sublinear knots give small screens relatively bigger UI
-- and large screens relatively smaller.
local function spline(knots: { monotoneSpline.Knot }): Curve
	local curve = monotoneSpline(knots)
	return function(size: Vector2): number
		return curve(math.min(size.X, size.Y))
	end
end

-- RC's production-tuned Default knots.
local defaultCurve = spline({ { 300, 0.5 }, { 800, 1 } })

local viewportScale = defaultCurve(camera.ViewportSize)
camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
	viewportScale = defaultCurve(camera.ViewportSize)
end)

-- Factors are computed once at push time; immediate mode re-pushes every
-- frame, so holder sizes never go stale.
local scaleContext = Context(nil :: number?)

local function current(): number
	return scaleContext.consume() or viewportScale
end

local function push(config: Config)
	local size = if config.holder then config.holder.AbsoluteSize else camera.ViewportSize
	local factor = config.factor or (config.curve or defaultCurve)(size)
	scaleContext.push(factor * (config.scale or 1))
end

local pop = scaleContext.pop

local function scope<T>(config: Config, fn: () -> T): T
	push(config)
	local result = fn()
	pop()
	return result
end

-- Scale components pass through untouched; only Offset lives in pixel space.
local scaleFunctions = {
	number = function(value: number, scale: number)
		return math.round(value * scale)
	end,
	UDim2 = function(value: UDim2, scale: number)
		return UDim2.new(
			value.X.Scale,
			math.round(value.X.Offset * scale),
			value.Y.Scale,
			math.round(value.Y.Offset * scale)
		)
	end,
	UDim = function(value: UDim, scale: number)
		return UDim.new(value.Scale, math.round(value.Offset * scale))
	end,
	Vector2 = function(value: Vector2, scale: number)
		return Vector2.new(math.round(value.X * scale), math.round(value.Y * scale))
	end,
}

local px = setmetatable({
	even = function(value: number)
		return math.round(value * current() * 0.5) * 2
	end,
	scale = function(value: number)
		return value * current()
	end,
	floor = function(value: number)
		return math.floor(value * current())
	end,
	ceil = function(value: number)
		return math.ceil(value * current())
	end,
}, {
	__call = function(_, value)
		local fn = scaleFunctions[typeof(value)] or error(`px: cannot scale a {typeof(value)}`)
		return fn(value, current())
	end,
})

return {
	px = px,
	push = push,
	pop = pop,
	scope = scope,
	spline = spline,
}
