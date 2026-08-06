export type Knot = { number }
export type Curve = (Vector2) -> number

local function curve(knots: { Knot }): Curve
	local amount = #knots
	assert(amount > 0, "curve: at least one knot required")

	local sorted = table.clone(knots)
	table.sort(sorted, function(a: Knot, b: Knot)
		return a[1] < b[1]
	end)

	if amount == 1 then
		local value = sorted[1][2]
		return function()
			return value
		end
	end

	return function(size: Vector2): number
		local x = math.min(size.X, size.Y)
		local i = amount - 1
		for j = 1, amount - 2 do
			if x < sorted[j + 1][1] then
				i = j
				break
			end
		end
		local a, b = sorted[i], sorted[i + 1]
		local t = (x - a[1]) / (b[1] - a[1])
		return a[2] + t * (b[2] - a[2])
	end
end

return curve
