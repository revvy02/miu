-- Mount and unmount: a keyed list of 200 whose window slides by 20 every walk, so 20 rows mount and
-- 20 are pruned each time.
local COUNT = 200
local STEP = 20

return function(pkgs)
	local Element = pkgs.miu.Element

	return {
		name = "churn",
		summary = `keyed list of {COUNT}, {STEP} swapped per walk`,
		expectedInstances = COUNT,
		render = function(walk)
			local first = walk * STEP
			for key = first, first + COUNT - 1 do
				Element("Frame", { id = key, Size = UDim2.fromOffset(20, 20) })
			end
		end,
	}
end
