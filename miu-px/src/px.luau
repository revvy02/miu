local PxCanvas = require("./PxCanvas")
local PxScale = require("./PxScale")

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
		return math.round(value * (PxCanvas() * PxScale()) * 0.5) * 2
	end,
	scale = function(value: number)
		return value * (PxCanvas() * PxScale())
	end,
	floor = function(value: number)
		return math.floor(value * (PxCanvas() * PxScale()))
	end,
	ceil = function(value: number)
		return math.ceil(value * (PxCanvas() * PxScale()))
	end,
}, {
	__call = function(_, value)
		local fn = scaleFunctions[typeof(value)] or error(`px: cannot scale a {typeof(value)}`)
		return fn(value, (PxCanvas() * PxScale()))
	end,
})

return px
