local miu = require("./scope")
local unmounting = require("./unmounting")

local function on_remove(_parent, _id, child)
	unmounting(child)
end

local function reactor_pop()
	miu.prune(miu.peek(), on_remove)
	miu.pop()
end

local function push(target, id)
	local node = miu.push(id)
	node.isPortal = true
	node.instance = target
	return node
end

local function pop()
	reactor_pop()
end

local function scope(target, id, fn)
	local node = push(target, id)
	if fn then
		fn(node)
	end
	reactor_pop()
	return node
end

return setmetatable({
	push = push,
	pop = pop,
}, {
	__call = function(_, target, id, fn)
		return scope(target, id, fn)
	end,
})
