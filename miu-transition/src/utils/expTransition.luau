local function expTransition(current: number, target: number, rate: number, dt: number): number
	if math.abs(target - current) < 0.01 then
		return target
	end

	local result = target + (current - target) * math.exp(-rate * dt)

	if math.abs(target - result) < 0.01 then
		return target
	end

	return result
end

return expTransition
