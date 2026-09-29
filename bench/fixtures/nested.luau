-- Scope push/pop/prune cost: a static tree, depth 6 with 3 children per node.
local DEPTH = 6
local FANOUT = 3

local count = 0
for level = 1, DEPTH do
	count += FANOUT ^ level
end

return function(pkgs)
	local Element = pkgs.miu.Element

	local function branch(depth)
		for n = 1, FANOUT do
			Element(
				"Frame",
				{ id = n, Size = UDim2.fromScale(0.5, 0.5) },
				if depth > 1
					then function()
						branch(depth - 1)
					end
					else nil
			)
		end
	end

	return {
		name = "nested",
		summary = `static tree, depth {DEPTH} x {FANOUT}`,
		expectedInstances = count,
		render = function()
			branch(DEPTH)
		end,
	}
end
