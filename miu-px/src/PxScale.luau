local Miu = require("../miu")

local scale = 1

local PxStack: Miu.Context<number> = Miu.Context(1)

local function push(factor: number)
	PxStack.push(scale)
	scale *= factor
end

local function pop()
	scale = PxStack()
	PxStack.pop()
end

local function peek(): number
	return scale
end

return (
	setmetatable({
		push = push,
		pop = pop,
		peek = peek,
	}, {
		__call = function(_, factor: number, render: (scale: number) -> ()): number
			if factor == nil and render == nil then
				return scale
			end
			push(factor)
			render(scale)
			pop()
			return factor
		end,
	})
) :: Miu.Context<number>
