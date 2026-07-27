local scope = require("./scope")

-- Seconds since this call site last ran, kept on its own persistent node so
-- every caller measures its own cadence.
local function DeltaTime(id)
	local node = scope.push(id)

	local now = os.clock()
	if not node.time then
		node.time = now
	end
	local dt = now - node.time
	node.time = now

	scope.pop()

	return dt
end

return DeltaTime
