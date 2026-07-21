local Element = require("../miu").Element

local function StyleSheet(fn)
	return Element("StyleSheet", {}, fn).instance
end

return StyleSheet
