local StyleRule = require("./StyleRule")
local px = require("../miu_px").px

return function(palette, fonts)
	local p = palette.palette

	-------------------------------------------------------
	-- TEXT BASE RESET (priority 0)
	-------------------------------------------------------

	StyleRule(".text", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(0, 0),
		AutomaticSize = Enum.AutomaticSize.XY,
		TextColor3 = p.text,
		TextXAlignment = Enum.TextXAlignment.Left,
	})

	-------------------------------------------------------
	-- TEXT ROLES (priority 0)
	-------------------------------------------------------

	StyleRule(".title", {
		FontFace = fonts.inter.bold,
		TextSize = px(20),
	})

	StyleRule(".heading", {
		FontFace = fonts.inter.bold,
		TextSize = px(15),
	})

	StyleRule(".label", {
		FontFace = fonts.inter.regular,
		TextSize = px(12),
	})

	StyleRule(".body", {
		FontFace = fonts.inter.regular,
		TextSize = px(14),
		TextWrapped = true,
	})

	StyleRule(".caption", {
		FontFace = fonts.inter.regular,
		TextSize = px(10),
		TextColor3 = p.subtext0,
	})

	StyleRule(".mono", {
		Font = Enum.Font.RobotoMono,
		TextSize = px(12),
	})

	StyleRule(".value", {
		Font = Enum.Font.RobotoMono,
		TextSize = px(12),
		TextXAlignment = Enum.TextXAlignment.Right,
		TextColor3 = p.green,
	})

	-------------------------------------------------------
	-- SURFACES (priority 0)
	-------------------------------------------------------

	StyleRule(".surface", {
		BackgroundColor3 = p.base,
		BackgroundTransparency = 0,
	})

	StyleRule(".surface-raised", {
		BackgroundColor3 = p.surface0,
		BackgroundTransparency = 0,
	})

	StyleRule(".surface-sunken", {
		BackgroundColor3 = p.mantle,
		BackgroundTransparency = 0,
	})

	StyleRule(".overlay", {
		BackgroundColor3 = p.crust,
		BackgroundTransparency = 0.1,
	})

	-------------------------------------------------------
	-- STATE MODIFIERS (priority 1 — override role colors)
	-------------------------------------------------------

	StyleRule(".selected", { TextColor3 = p.blue }, nil, 1)
	StyleRule(".expanded", { TextColor3 = p.green }, nil, 1)
	StyleRule(".on-path", { TextColor3 = p.yellow }, nil, 1)
	StyleRule(".muted", { TextColor3 = p.overlay1 }, nil, 1)
	StyleRule(".accent", { TextColor3 = p.sky }, nil, 1)
	StyleRule(".disabled", { TextColor3 = p.surface2 }, nil, 1)
end
