local Element = require("../miu").Element

local function StyleLink(styleSheet)
	return Element("StyleLink", { StyleSheet = styleSheet })
end

return StyleLink
