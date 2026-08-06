export type Context<T> = typeof(setmetatable(
	{} :: {
		push: (value: T) -> (),
		pop: () -> (),
		consume: () -> T,
	},
	{} :: {
		__call: ((self: unknown) -> T) & ((self: unknown, value: T, fn: () -> ()) -> ()),
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

	local function consume(): T
		return stack[#stack]
	end

	return (
		setmetatable({
			push = push,
			pop = pop,
			consume = consume,
		}, {
			__call = function(_, value: T, fn: () -> ())
				if value == nil and fn == nil then
					return consume()
				else
					push(value)
					fn()
					pop()
					return nil
				end
			end,
		})
	) :: Context<T>
end

return Context
