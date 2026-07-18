local camera = workspace.CurrentCamera

local BASE_RESOLUTION = Vector2.new(1280, 832)
local MIN_SCALE = 0.5
local DOMINANT_AXIS = 0.5

local scaleValue = 1

local function update()
	local width = math.log(camera.ViewportSize.X / BASE_RESOLUTION.X, 2)
	local height = math.log(camera.ViewportSize.Y / BASE_RESOLUTION.Y, 2)
	local centered = width + (height - width) * DOMINANT_AXIS
	scaleValue = math.max(2 ^ centered, MIN_SCALE)
end

update()
camera:GetPropertyChangedSignal("ViewportSize"):Connect(update)

local px = setmetatable({
	even = function(value: number)
		return math.round(value * scaleValue * 0.5) * 2
	end,
	scale = function(value: number)
		return value * scaleValue
	end,
	floor = function(value: number)
		return math.floor(value * scaleValue)
	end,
	ceil = function(value: number)
		return math.ceil(value * scaleValue)
	end,
}, {
	__call = function(_, value: number)
		return math.round(value * scaleValue)
	end,
})

return {
	px = px,
}
