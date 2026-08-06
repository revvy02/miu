export type Context<In, Out = In> = typeof(setmetatable(
	{} :: {
		push: (value: In) -> (),
		pop: () -> (),
		peek: () -> Out,
	},
	{} :: {
		__call: ((self: unknown) -> Out) & ((self: unknown, value: In, fn: (value: Out) -> ()) -> In),
	}
))

local function Context<T>(default: T): Context<T>
	local stack = { default }

	local function push(value: T)
		table.insert(stack, value)
	end

	local function pop()
		table.remove(stack)
	end

	local function peek(): T
		return stack[#stack]
	end

	local function scope(value: T, fn: (T) -> ()): T
		push(value)
		fn(value)
		pop()
		return value
	end

	return (
		setmetatable({
			push = push,
			pop = pop,
			peek = peek,
		}, {
			__call = function(_, value: T, fn: (T) -> ()): T
				if value == nil and fn == nil then
					return peek()
				else
					return scope(value, fn)
				end
			end,
		})
	) :: Context<T>
end

return Context
