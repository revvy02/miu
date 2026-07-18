local Instance = require("../miu").Instance

local function StyleSheet(fn)
	return Instance("StyleSheet", {}, fn).instance
end

return StyleSheet
