local Miu = require("../miu")

-- Its state is a miu node in the scope it's called from: the next in call order, or the one named
-- `id` (pass one for a dictionary that's called conditionally or in a loop).
local function RemovingDictionary(dict, lifetime, id)
	lifetime = lifetime or 1

	local state = Miu(id)
	local merged, removing = state.merged, state.removing

	if not merged then
		merged = {}
		removing = {}
		state.merged = merged
		state.removing = removing
	end

	local t0 = os.clock()

	for k, v in dict do
		if merged[k] ~= v then -- item k from dict got added / value changed
			merged[k] = v
		end
		if removing[k] then -- cancel removal
			removing[k] = nil
		end
	end

	for k in merged do
		if dict[k] == nil and not removing[k] then -- item k is removed from dict
			removing[k] = t0
		end
	end

	for k, t1 in removing do
		if t0 - t1 >= lifetime then -- complete removal
			merged[k] = nil
			removing[k] = nil
		end
	end

	return merged, removing
end

return RemovingDictionary
