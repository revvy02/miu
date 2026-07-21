local Context = require("@self/Context")
local Element = require("@self/Element")
local Portal = require("@self/Portal")
local scope = require("@self/scope")

export type MiuNode<T = {}> = scope.MiuNode<T>

local Miu = setmetatable({
	push = scope.push,
	pop = scope.pop,
	peek = scope.peek,
	root = scope.root,
	Context = Context,
	Element = Element,
	Portal = Portal,
}, {
	__call = function(_, id, fn)
		return scope(id, fn)
	end,
})

return Miu
