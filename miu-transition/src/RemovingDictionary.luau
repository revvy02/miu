local Miu = require("../miu")

local function RemovingDictionary(dict, lifetime)
	lifetime = lifetime or 1

	local state = Miu("RemovingDictionary")
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
