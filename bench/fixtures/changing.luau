-- The write path: 500 TextLabels whose Text changes every walk, so every element writes.
local Element = require("../pkgs").miu.Element

local COUNT = 500

return {
	name = "changing",
	summary = `{COUNT} TextLabels, new Text every walk`,
	expectedInstances = COUNT,
	render = function(walk)
		for n = 1, COUNT do
			Element("TextLabel", {
				id = n,
				Size = UDim2.fromOffset(40, 12),
				Text = tostring(walk + n),
			})
		end
	end,
}
