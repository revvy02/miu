local UILabs = require("../ui_labs")

local Element = require("../miu").Element
local MiuStory = require("../miu_ui_labs").MiuStory
local px = require("../miu_px").px

local Float = require("./Float")

local HEADER_COLOR = Color3.fromRGB(160, 160, 170)
local LABEL_COLOR = Color3.fromRGB(200, 200, 200)
local OVERLAY_COLOR = Color3.fromRGB(100, 140, 200)

local function header(text)
	Element("TextLabel", {
		Size = UDim2.new(1, 0, 0, px(20)),
		BackgroundTransparency = 1,
		Text = text,
		TextColor3 = HEADER_COLOR,
		TextSize = px(13),
		TextXAlignment = Enum.TextXAlignment.Left,
		FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold),
	})
end

local function renderOverlay()
	Element("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = OVERLAY_COLOR,
		BackgroundTransparency = 0.7,
	})
end

return MiuStory({
	name = "Float",
	summary = "Layout container with content positioning, transforms, AutomaticSize, and renderFloatingChildren",
	controls = {
		widthTransform = UILabs.Slider(1, 0, 1, 0.01),
		heightTransform = UILabs.Slider(1, 0, 1, 0.01),
	},
}, function(controls)
	Element.push("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = px(4),
		BorderSizePixel = 0,
	})

	Element("UIListLayout", {
		Padding = UDim.new(0, px(24)),
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
	})

	Element("UIPadding", {
		PaddingTop = UDim.new(0, px(16)),
		PaddingBottom = UDim.new(0, px(16)),
		PaddingLeft = UDim.new(0, px(16)),
		PaddingRight = UDim.new(0, px(16)),
	})

	-- Fixed offset size
	Element.push("Frame", {
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
	})
	Element("UIListLayout", { Padding = UDim.new(0, px(8)) })

	header("Fixed offset — UDim2.fromOffset(250, 100)")

	Float({
		size = UDim2.fromOffset(px(250), px(100)),
		widthTransform = controls.widthTransform,
		heightTransform = controls.heightTransform,
		backgroundColor3 = Color3.fromRGB(50, 50, 55),
		backgroundTransparency = 0,
		renderFloatingChildren = renderOverlay,
	}, function()
		Element("UIListLayout", { Padding = UDim.new(0, px(4)) })
		Element("UIPadding", {
			PaddingTop = UDim.new(0, px(8)),
			PaddingBottom = UDim.new(0, px(8)),
			PaddingLeft = UDim.new(0, px(8)),
			PaddingRight = UDim.new(0, px(8)),
		})
		for i = 1, 3 do
			Element("TextLabel", {
				Size = UDim2.new(1, 0, 0, px(20)),
				BackgroundTransparency = 1,
				Text = `Line {i}`,
				TextColor3 = LABEL_COLOR,
				TextSize = px(14),
			})
		end
	end)

	Element.pop()

	-- Fixed scale size
	Element.push("Frame", {
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
	})
	Element("UIListLayout", { Padding = UDim.new(0, px(8)) })

	header("Fixed scale — UDim2.fromScale(0.5, 0) + offset height")

	Float({
		size = UDim2.new(0.5, 0, 0, px(80)),
		widthTransform = controls.widthTransform,
		heightTransform = controls.heightTransform,
		backgroundColor3 = Color3.fromRGB(55, 50, 50),
		backgroundTransparency = 0,
		renderFloatingChildren = renderOverlay,
	}, function()
		Element("UIListLayout", { Padding = UDim.new(0, px(4)) })
		Element("UIPadding", {
			PaddingTop = UDim.new(0, px(8)),
			PaddingBottom = UDim.new(0, px(8)),
			PaddingLeft = UDim.new(0, px(8)),
			PaddingRight = UDim.new(0, px(8)),
		})
		for i = 1, 2 do
			Element("TextLabel", {
				Size = UDim2.new(1, 0, 0, px(20)),
				BackgroundTransparency = 1,
				Text = `Line {i}`,
				TextColor3 = LABEL_COLOR,
				TextSize = px(14),
			})
		end
	end)

	Element.pop()

	-- AutomaticSize.Y
	Element.push("Frame", {
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
	})
	Element("UIListLayout", { Padding = UDim.new(0, px(8)) })

	header("AutomaticSize.Y — fixed width, height from content")

	Float({
		size = UDim2.fromOffset(px(250), 0),
		automaticSize = Enum.AutomaticSize.Y,
		widthTransform = controls.widthTransform,
		heightTransform = controls.heightTransform,
		backgroundColor3 = Color3.fromRGB(45, 55, 45),
		backgroundTransparency = 0,
		renderFloatingChildren = renderOverlay,
	}, function()
		Element("UIListLayout", { Padding = UDim.new(0, px(4)) })
		Element("UIPadding", {
			PaddingTop = UDim.new(0, px(8)),
			PaddingBottom = UDim.new(0, px(8)),
			PaddingLeft = UDim.new(0, px(8)),
			PaddingRight = UDim.new(0, px(8)),
		})
		for i = 1, 4 do
			Element("TextLabel", {
				Size = UDim2.new(1, 0, 0, px(20)),
				BackgroundTransparency = 1,
				Text = `Line {i}`,
				TextColor3 = LABEL_COLOR,
				TextSize = px(14),
			})
		end
	end)

	Element.pop()

	-- AutomaticSize.X
	Element.push("Frame", {
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
	})
	Element("UIListLayout", { Padding = UDim.new(0, px(8)) })

	header("AutomaticSize.X — fixed height, width from content")

	Float({
		size = UDim2.fromOffset(0, px(50)),
		automaticSize = Enum.AutomaticSize.X,
		widthTransform = controls.widthTransform,
		heightTransform = controls.heightTransform,
		backgroundColor3 = Color3.fromRGB(55, 45, 55),
		backgroundTransparency = 0,
		renderFloatingChildren = renderOverlay,
	}, function()
		Element("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, px(8)),
		})
		Element("UIPadding", {
			PaddingTop = UDim.new(0, px(8)),
			PaddingBottom = UDim.new(0, px(8)),
			PaddingLeft = UDim.new(0, px(8)),
			PaddingRight = UDim.new(0, px(8)),
		})
		for i = 1, 4 do
			Element("TextLabel", {
				Size = UDim2.fromOffset(px(60), px(30)),
				BackgroundColor3 = Color3.fromRGB(70, 60, 75),
				BackgroundTransparency = 0,
				Text = `Item {i}`,
				TextColor3 = LABEL_COLOR,
				TextSize = px(12),
			})
		end
	end)

	Element.pop()

	-- AutomaticSize.XY
	Element.push("Frame", {
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
	})
	Element("UIListLayout", { Padding = UDim.new(0, px(8)) })

	header("AutomaticSize.XY — both axes from content")

	Float({
		size = UDim2.new(),
		automaticSize = Enum.AutomaticSize.XY,
		widthTransform = controls.widthTransform,
		heightTransform = controls.heightTransform,
		backgroundColor3 = Color3.fromRGB(45, 50, 60),
		backgroundTransparency = 0,
		renderFloatingChildren = renderOverlay,
	}, function()
		Element("UIListLayout", { Padding = UDim.new(0, px(4)) })
		Element("UIPadding", {
			PaddingTop = UDim.new(0, px(8)),
			PaddingBottom = UDim.new(0, px(8)),
			PaddingLeft = UDim.new(0, px(8)),
			PaddingRight = UDim.new(0, px(8)),
		})
		for i = 1, 3 do
			Element("TextLabel", {
				Size = UDim2.fromOffset(px(180), px(20)),
				BackgroundTransparency = 1,
				Text = `Content line {i}`,
				TextColor3 = LABEL_COLOR,
				TextSize = px(14),
			})
		end
	end)

	Element.pop()

	Element.pop()
end)
