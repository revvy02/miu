--!native
--!optimize 2
--!strict

export type Node<T = {}> = {
	parent: Node,
	children: { [string | number]: Node },
	visited: boolean,
	cursor: number,
} & T

export type Accumulator<T = {}> = {
	on_enter: ((node: Node<T>) -> ())?,
	on_exit: ((node: Node<T>) -> ())?,
	resolve: ((parent: Node<T>, id: string | number) -> Node<T>?)?,
	attach: ((parent: Node<T>, node: Node<T>) -> ())?,
}

local function prune(node: Node, on_remove: ((parent: Node, id: string | number, child: Node) -> ())?)
	for id, child in node.children do
		if child.visited then
			child.visited = false
		else
			prune(child, on_remove)
			if on_remove then
				on_remove(node, id, child)
			else
				node.children[id] = nil
			end
		end
	end
end

local function RetainedScope<T>(acc: Accumulator<T>?, root: Node<T>?, state: { node: Node<T> }?)
	root = root or { cursor = 0, children = {}, parent = nil } :: any
	state = state or { node = root }

	local on_enter = acc and acc.on_enter
	local on_exit = acc and acc.on_exit
	local resolve = acc and acc.resolve
	local attach = acc and acc.attach

	local function push<U>(id): Node<U>
		local parent = state.node

		if not id then
			parent.cursor += 1
			id = parent.cursor
		end

		local child

		if resolve then
			child = resolve(parent, id)
		else
			child = parent.children[id]
		end

		if not child then
			child = { id = id, parent = parent, children = {}, cursor = 0 }
		end

		if attach then
			attach(parent, child)
		else
			parent.children[id] = child
		end

		child.visited = true
		state.node = child

		if on_enter then
			on_enter(child)
		end

		return child :: any
	end

	local function pop()
		local current = state.node

		if on_exit then
			on_exit(current)
		end

		current.cursor = 0
		state.node = current.parent
	end

	local function peek<U>(): Node<U>
		return state.node :: any
	end

	local function scope<U>(id, fn: ((Node<U>) -> ())?): Node<U>
		local node = push(id)
		if fn then
			fn(node)
		end
		pop()
		return node :: any
	end

	return setmetatable({
		push = push,
		pop = pop,
		peek = peek,
		prune = prune,
		root = root,
		state = state,
		scope = scope,
	}, {
		__call = function(_, id, fn)
			return scope(id, fn)
		end,
	})
end

return RetainedScope
