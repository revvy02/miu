-- The measured hot spot in a real game: every UI walks its own WindRules sheet every frame. Eight
-- sheets, as the game had eight UIs doing this.
local pkgs = require("../pkgs")
local Element = pkgs.miu.Element
local StyleLink = pkgs.wind.StyleLink
local StyleSheet = pkgs.wind.StyleSheet
local WindRules = pkgs.wind.WindRules

local SHEETS = 8

return {
	name = "stylesheet",
	summary = `{SHEETS} x StyleLink(StyleSheet(WindRules))`,
	render = function()
		for n = 1, SHEETS do
			Element("Folder", { id = n }, function()
				StyleLink(StyleSheet(WindRules))
			end)
		end
	end,
}
