local StyleRule = require("./StyleRule")
local px = require("../miu_px").px

-- Markdown-like convenience aliases.
-- Each rule is self-contained (doesn't depend on ThemeRules tags).
-- State modifiers (selected, muted, etc.) from ThemeRules at priority 1
-- override these at priority 0.
return function(palette, fonts)
	local p = palette.palette

	local TEXT_RESET = {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(0, 0),
		AutomaticSize = Enum.AutomaticSize.XY,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = p.text,
	}

	local function textRule(selector, overrides)
		local props = table.clone(TEXT_RESET)
		for k, v in overrides do
			props[k] = v
		end
		StyleRule(selector, props)
	end

	textRule(".h1", { FontFace = fonts.inter.bold, TextSize = px(22) })
	textRule(".h2", { FontFace = fonts.inter.bold, TextSize = px(17) })
	textRule(".h3", { FontFace = fonts.inter.bold, TextSize = px(15) })

	textRule(".p", { FontFace = fonts.inter.regular, TextSize = px(16), TextWrapped = true })

	textRule(".code", { Font = Enum.Font.RobotoMono, TextSize = px(14) })
end
