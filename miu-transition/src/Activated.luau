local Miu = require("../miu")

local function Activated(cooldown, instance)
	instance = instance or Miu.peek().instance

	local node = Miu()

	local pressed = instance.GuiState == Enum.GuiState.Press
	local wasPressed = node.pressed or false

	node.pressed = pressed

	-- Rising edge + cooldown
	local now = os.clock()
	local activated = pressed and not wasPressed and (now - (node.lastActivated or 0)) >= (cooldown or 0)
	if activated then
		node.lastActivated = now
	end

	return activated
end

return Activated
