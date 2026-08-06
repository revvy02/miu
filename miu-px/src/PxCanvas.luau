local Miu = require("../miu")
local curve = require("./curve")
local presets = require("./presets")

type Curve = curve.Curve

export type Config = {
	holder: GuiObject?,
	curve: Curve?,
	factor: number?,
}

-- Cached so unscoped px() calls don't pay an Instance property read; re-hooked
-- on CurrentCamera replacement (respawn, streaming) so it never goes stale.
local viewportScale = 1
local viewportConnection: RBXScriptConnection? = nil

local function watchCamera()
	if viewportConnection then
		viewportConnection:Disconnect()
		viewportConnection = nil
	end
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	viewportScale = presets.default(camera.ViewportSize)
	viewportConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
		viewportScale = presets.default(camera.ViewportSize)
	end)
end

watchCamera()
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(watchCamera)

local context: Miu.Context<number?> = Miu.Context(nil :: number?)

-- Factors are computed once at push time; immediate mode re-pushes every
-- frame, so holder sizes never go stale.
local function push(config: Config)
	local size = if config.holder then config.holder.AbsoluteSize else workspace.CurrentCamera.ViewportSize
	local factor = config.factor or (config.curve or presets.default)(size)
	context.push(factor)
end

local pop = context.pop

-- The screen is the canvas when none is pushed.
local function peek(): number
	return context.peek() or viewportScale
end

local PxCanvas = setmetatable({
	push = push,
	pop = pop,
	peek = peek,
}, {
	__call = function(_, config: Config, fn: (scale: number) -> ()): Config
		if config == nil and fn == nil then
			return peek() :: any
		end
		push(config)
		fn(peek())
		pop()
		return config
	end,
}) :: Miu.Context<Config, number>

return PxCanvas
