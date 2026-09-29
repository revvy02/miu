-- Per-element cost of a walk that changes nothing: 500 static sibling Frames.
local Element = require("../pkgs").miu.Element

local COUNT = 500

return {
	name = "flat",
	summary = `{COUNT} static Frames`,
	expectedInstances = COUNT,
	render = function()
		for n = 1, COUNT do
			Element("Frame", {
				id = n,
				Size = UDim2.fromOffset(10, 10),
				Position = UDim2.fromOffset(n % 50 * 12, n // 50 * 12),
				BackgroundColor3 = Color3.new(1, 1, 1),
			})
		end
	end,
}
