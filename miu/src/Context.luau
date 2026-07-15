local function Context(default)
	local stack = { default }

	local function push(value)
		table.insert(stack, value)
	end

	local function pop()
		table.remove(stack)
	end

	local function consume()
		return stack[#stack]
	end

	return setmetatable({
		push = push,
		pop = pop,
		consume = consume,
	}, {
		__call = function(_, value, fn)
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
end

return Context
