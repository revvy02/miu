-- Float/Transition while animating: 50 settled and 50 flipping rows interleaved in one list. Each
-- flipping row's size write makes the next Float's measurement force a layout of the list.
local COUNT = 50

return function(pkgs)
	local transitionList = require("../transitionList")(pkgs)

	return {
		name = "transitions",
		summary = `{COUNT} settled + {COUNT} flipping Transitions`,
		warmupSeconds = 1, -- Transitions start hidden and take ~0.4s of real time to settle
		render = function(walk)
			transitionList(walk, COUNT, COUNT)
		end,
	}
end
