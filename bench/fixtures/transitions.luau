-- Float/Transition: 50 settled Transitions and 50 that flip `show` every walk, each around a label.
-- Transitions ease by real elapsed time, so in a tight loop the flipping ones barely move, but they
-- still rewrite their size every walk, and each write makes the next Float's measurement force a
-- layout of the list. The label renders even while hidden, so the instance count stays fixed.
local pkgs = require("../pkgs")
local Element = pkgs.miu.Element
local Transition = pkgs.transition.Transition

local COUNT = 50

local function row(id, show)
	Transition({
		id = id,
		show = show,
		preset = "collapseHeight",
		size = UDim2.fromScale(1, 0),
		automaticSize = Enum.AutomaticSize.Y,
	}, function()
		Element("TextLabel", { Size = UDim2.new(1, 0, 0, 16), Text = id })
	end)
end

return {
	name = "transitions",
	summary = `{COUNT} settled + {COUNT} flipping Transitions`,
	render = function(walk)
		Element("Frame", { id = "list", Size = UDim2.fromScale(1, 1) }, function()
			Element("UIListLayout", {})
			for n = 1, COUNT do
				row("settled" .. n, true)
				row("flipping" .. n, walk % 2 == 0)
			end
		end)
	end,
}
