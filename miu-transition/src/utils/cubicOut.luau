-- Ease-out cubic over a clamped alpha (curve.clamped.cubicOut).
local function cubicOut(x: number): number
	local t = math.clamp(x, 0, 1)
	return 1 - (1 - t) ^ 3
end

return cubicOut
