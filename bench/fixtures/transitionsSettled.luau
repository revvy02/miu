-- The same list with every row settled: no size changes, so nothing forces a layout. Against
-- `transitions`, the difference is what the flipping rows' layouts cost.
local COUNT = 100

return function(pkgs)
	local transitionList = require("../transitionList")(pkgs)

	return {
		name = "transitions-settled",
		summary = `{COUNT} settled Transitions`,
		warmupSeconds = 1, -- Transitions start hidden and take ~0.4s of real time to settle
		render = function(walk)
			transitionList(walk, COUNT, 0)
		end,
	}
end
