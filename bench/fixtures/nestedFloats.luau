-- An auto-sized Float around a list of 20 auto-sized Floats that switch between half and full
-- height every walk. The check holds the outer Float to this walk's inner sizes: however Float
-- schedules its size writes, an ancestor must measure after its descendants' writes have landed,
-- or the outer size trails the inner ones by a walk.
local pkgs = require("../pkgs")
local Element = pkgs.miu.Element
local Float = pkgs.transition.Float

local COUNT = 20
local TOLERANCE = 2 -- px: Float's pixel bias and offset rounding; a stale outer is off by >= 8px per row

return {
	name = "nestedFloats",
	summary = `auto Float around {COUNT} resizing auto Floats`,
	render = function(walk)
		local half = walk % 2 == 0
		Float({ id = "outer", size = UDim2.new(0, 200, 0, 0), automaticSize = Enum.AutomaticSize.Y }, function()
			Element("UIListLayout", {})
			for n = 1, COUNT do
				Float({
					id = "inner" .. n,
					size = UDim2.fromScale(1, 0),
					automaticSize = Enum.AutomaticSize.Y,
					heightTransform = if half then 0.5 else 1,
				}, function()
					Element("Frame", { Size = UDim2.new(1, 0, 0, 16) })
				end)
			end
		end)
	end,
	check = function(gui: ScreenGui): string?
		local outer = gui:FindFirstChild("outer", true) :: Frame
		local sum = 0
		for n = 1, COUNT do
			sum += (outer:FindFirstChild("inner" .. n, true) :: Frame).AbsoluteSize.Y
		end
		local height = outer.AbsoluteSize.Y
		if math.abs(height - sum) > TOLERANCE then
			return `outer Float is {height}px but its inner Floats add up to {sum}px`
		end
		return nil
	end,
}
