-- Tag diffing: 500 static Frames with three tags each, passed as a fresh table every walk like an
-- inline literal.
local Element = require("../pkgs").miu.Element

local COUNT = 500

return {
	name = "tagged",
	summary = `{COUNT} static Frames with 3 tags`,
	expectedInstances = COUNT,
	render = function()
		for n = 1, COUNT do
			Element("Frame", { id = n, tags = { "bg-none", "flex-row", "gap-sm" } })
		end
	end,
}
