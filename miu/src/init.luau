local Context = require("@self/Context")
local DeltaTime = require("@self/DeltaTime")
local Element = require("@self/Element")
local Portal = require("@self/Portal")
local scope = require("@self/scope")

export type MiuNode<T = {}> = scope.MiuNode<T>
export type Context<In, Out = In> = Context.Context<In, Out>

local Miu = setmetatable({
	push = scope.push,
	pop = scope.pop,
	peek = scope.peek,
	defer = scope.defer,
	root = scope.root,
	Context = Context,
	DeltaTime = DeltaTime,
	Element = Element,
	Portal = Portal,
}, {
	__call = function(_, id, fn)
		return scope(id, fn)
	end,
})

return Miu
