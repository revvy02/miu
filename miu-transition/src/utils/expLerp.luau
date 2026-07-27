local function expLerp<T>(current: T, target: T, rate: number, dt: number): T
	return target + (current - target) * math.exp(-rate * dt)
end

return expLerp
