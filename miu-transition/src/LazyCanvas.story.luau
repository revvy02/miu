local UILabs = require("../ui_labs")

local Element = require("../miu").Element
local MiuStory = require("../miu_ui_labs").MiuStory
local px = require("../miu_px").px

local LazyCanvas = require("./LazyCanvas")

return MiuStory({
	name = "LazyCanvas",
	summary = "Switches between Frame (performant) and CanvasGroup (transparency) based on threshold",
	controls = {
		groupTransparency = UILabs.Slider(0, 0, 1, 0.01),
	},
}, function(controls)
	Element.push("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	})

	LazyCanvas({
		groupTransparency = controls.groupTransparency,
		size = UDim2.fromOffset(px(400), px(250)),
		position = UDim2.fromScale(0.5, 0.5),
		anchorPoint = Vector2.new(0.5, 0.5),
	}, function()
		Element("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			Padding = UDim.new(0, px(8)),
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
		})

		local colors = {
			Color3.fromRGB(220, 80, 80),
			Color3.fromRGB(80, 180, 80),
			Color3.fromRGB(80, 120, 220),
		}

		for i, color in colors do
			Element("Frame", {
				Size = UDim2.new(0.8, 0, 0, px(50)),
				BackgroundColor3 = color,
				BackgroundTransparency = 0,
			}, function()
				Element("UICorner", { CornerRadius = UDim.new(0, px(6)) })
				Element("TextLabel", {
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					Text = `Block {i}`,
					TextColor3 = Color3.new(1, 1, 1),
					TextSize = px(14),
					FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold),
				})
			end)
		end
	end)

	Element.pop()
end)
