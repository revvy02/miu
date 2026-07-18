local Instance = require("../miu").Instance

local function StyleLink(styleSheet)
	return Instance("StyleLink", { StyleSheet = styleSheet })
end

return StyleLink
