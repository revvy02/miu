-- Builds a clean tag array, filtering nil/false values.
-- Usage: tags("text", "label", isSelected and "selected", onPath and "on-path")
return function(...): { string }
	local result = {}
	for i = 1, select("#", ...) do
		local v = select(i, ...)
		if v then
			table.insert(result, v)
		end
	end
	return result
end
