export type Knot = { number }

local X = 1
local Y = 2

local function binarySearch(xs: { number }, xq: number): number
	local n = #xs
	if xq >= xs[n] then
		return n - 1
	end
	local low, high = 1, n
	while low + 1 < high do
		local mid = (low + high) // 2
		if xs[mid] <= xq then
			low = mid
		else
			high = mid
		end
	end
	return low
end

-- Fritsch-Carlson monotone cubic Hermite interpolation with linear
-- extrapolation outside the knot range.
local function spline(knots: { Knot }): (number) -> number
	local amount = #knots
	if amount == 0 then
		error("spline: at least one knot required")
	elseif amount == 1 then
		local value = knots[1][Y]
		return function()
			return value
		end
	end

	table.sort(knots, function(a, b)
		return a[X] < b[X]
	end)

	local xs, ys = {}, {}
	for i = 1, amount do
		xs[i] = knots[i][X]
		ys[i] = knots[i][Y]
	end

	local intervals = table.create(amount - 1)
	local deltas = table.create(amount - 1)
	for i = 1, amount - 1 do
		local h = xs[i + 1] - xs[i]
		intervals[i] = h
		deltas[i] = (ys[i + 1] - ys[i]) / h
	end

	local tangents = table.create(amount)

	if amount == 2 then
		tangents[1] = deltas[1]
		tangents[2] = deltas[1]
	else
		for i = 2, amount - 1 do
			local d0, d1 = deltas[i], deltas[i - 1]
			if d0 == 0 or d1 == 0 or d1 * d0 <= 0 then
				tangents[i] = 0
			else
				local w1 = 2 * intervals[i] + intervals[i - 1]
				local w2 = intervals[i] + 2 * intervals[i - 1]
				tangents[i] = (w1 + w2) / (w1 / d1 + w2 / d0)
			end
		end

		do
			local d0, d1 = deltas[1], deltas[2]
			local h0, h1 = intervals[1], intervals[2]
			local m = ((2 * h0 + h1) * d0 - h0 * d1) / (h0 + h1)
			if math.sign(m) ~= math.sign(d0) then
				m = 0
			elseif math.sign(d0) ~= math.sign(d1) and math.abs(m) > math.abs(3 * d0) then
				m = 3 * d0
			end
			tangents[1] = m
		end

		do
			local d0, d1 = deltas[amount - 1], deltas[amount - 2]
			local h0, h1 = intervals[amount - 1], intervals[amount - 2]
			local m = ((2 * h0 + h1) * d0 - h0 * d1) / (h0 + h1)
			if math.sign(m) ~= math.sign(d0) then
				m = 0
			elseif math.sign(d0) ~= math.sign(d1) and math.abs(m) > math.abs(3 * d0) then
				m = 3 * d0
			end
			tangents[amount] = m
		end
	end

	return function(x: number): number
		if x < xs[1] then
			return ys[1] + (x - xs[1]) * tangents[1]
		elseif x > xs[amount] then
			return ys[amount] + (x - xs[amount]) * tangents[amount]
		end

		local i = binarySearch(xs, x)
		local h = intervals[i]
		local t = (x - xs[i]) / h

		local t2, t3 = t * t, t * t * t
		local h00 = 2 * t3 - 3 * t2 + 1
		local h10 = t3 - 2 * t2 + t
		local h01 = -2 * t3 + 3 * t2
		local h11 = t3 - t2
		return h00 * ys[i] + h10 * h * tangents[i] + h01 * ys[i + 1] + h11 * h * tangents[i + 1]
	end
end

return spline
