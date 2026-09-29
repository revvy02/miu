-- The list the Transition fixtures render: collapseHeight Transitions in one UIListLayout, each
-- around a label. `settled` rows always show; `flipping` rows flip `show` every walk. Transitions
-- ease by real elapsed time, so in a tight loop the flipping ones barely move, but they still write
-- a new size every walk. The label renders even while hidden, so the instance count stays fixed.
local pkgs = require("./pkgs")
local Element = pkgs.miu.Element
local Transition = pkgs.transition.Transition

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

return function(walk: number, settled: number, flipping: number)
	Element("Frame", { id = "list", Size = UDim2.fromScale(1, 1) }, function()
		Element("UIListLayout", {})
		for n = 1, math.max(settled, flipping) do
			if n <= settled then
				row("settled" .. n, true)
			end
			if n <= flipping then
				row("flipping" .. n, walk % 2 == 0)
			end
		end
	end)
end
