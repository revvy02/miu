local Element = require("../miu").Element
local Miu = require("../miu")
local MiuStory = require("../miu_ui_labs").MiuStory
local px = require("../miu_px").px

local Activated = require("./Activated")
local TransitionList = require("./TransitionList")

local HEADER_COLOR = Color3.fromRGB(160, 160, 170)
local LABEL_COLOR = Color3.fromRGB(200, 200, 200)
local CARD_COLOR = Color3.fromRGB(45, 50, 65)
local REMOVING_COLOR = Color3.fromRGB(80, 45, 50)

local POOL = { "Apple", "Banana", "Cherry", "Grape", "Lemon", "Mango", "Olive", "Peach" }

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

local function row(key, removing)
	Element("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = if removing then REMOVING_COLOR else CARD_COLOR,
		BackgroundTransparency = 0,
	}, function()
		Element("UICorner", { CornerRadius = UDim.new(0, px(6)) })
		Element("TextLabel", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Text = if removing then `{key} (removing)` else key,
			TextColor3 = LABEL_COLOR,
			TextSize = px(13),
		})
	end)
end

local function button(id, label)
	local clicked = false
	Element("TextButton", {
		id = id,
		Size = UDim2.fromOffset(px(90), px(26)),
		BackgroundColor3 = Color3.fromRGB(60, 65, 85),
		Text = label,
		TextColor3 = LABEL_COLOR,
		TextSize = px(13),
	}, function()
		Element("UICorner", { CornerRadius = UDim.new(0, px(4)) })
		clicked = Activated()
	end)
	return clicked
end

return MiuStory({
	name = "TransitionList",
	summary = "Animated list — staggered reveal/unravel and per-item enter/exit",
	controls = {
		show = true,
		trailDelay = 0.08,
	},
}, function(controls)
	Element("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = px(4),
		BorderSizePixel = 0,
	}, function()
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

		-- Trail reveal/unravel: `show` gates the whole list; the stagger runs on one
		-- reversible alpha, so flipping `show` mid-flight (spam the control) resumes
		-- from wherever the front got to — head-first in, tail-first out.
		Element("Frame", {
			id = "trail-section",
			Size = UDim2.fromOffset(px(300), 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
		}, function()
			Element("UIListLayout", { Padding = UDim.new(0, px(8)) })

			header("Trail — toggle `show` mid-flight to test reversal")

			local items = {}
			for i = 1, 6 do
				items[i] = { id = `Row {i}` }
			end

			local anyVisible
			Element("Frame", {
				id = "list",
				Size = UDim2.fromScale(1, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				LayoutOrder = 1,
			}, function()
				Element("UIListLayout", { Padding = UDim.new(0, px(4)) })

				anyVisible = TransitionList({
					items = items,
					show = controls.show,
					preset = "slideDiagonal",
					size = UDim2.new(1, 0, 0, px(30)),
					animateTrailDelay = controls.trailDelay,
				}, function(key, _item, removing)
					row(key, removing)
				end)
			end)

			Element("TextLabel", {
				Size = UDim2.new(1, 0, 0, px(16)),
				BackgroundTransparency = 1,
				Text = `anyVisible = {anyVisible}`,
				TextColor3 = HEADER_COLOR,
				TextSize = px(12),
				TextXAlignment = Enum.TextXAlignment.Left,
				LayoutOrder = 2,
			})
		end)

		-- Enter/exit: mutate the items array and each row animates in on add, out on
		-- remove (lifetime-driven unmount). Re-adding a row that is still animating
		-- out recovers it in place instead of restarting from hidden.
		Element("Frame", {
			id = "dynamic-section",
			Size = UDim2.fromOffset(px(300), 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
		}, function()
			Element("UIListLayout", { Padding = UDim.new(0, px(8)) })

			header("Enter/exit — remove then re-add fast to test recovery")

			local state = Miu("dynamic-state")
			if state.count == nil then
				state.count = 4
			end

			Element("Frame", {
				id = "buttons",
				Size = UDim2.fromScale(1, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				LayoutOrder = 1,
			}, function()
				Element("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					Padding = UDim.new(0, px(8)),
				})

				if button("add", "Add") then
					state.count = math.min(state.count + 1, #POOL)
				end
				if button("remove", "Remove") then
					state.count = math.max(state.count - 1, 0)
				end
			end)

			local items = {}
			for i = 1, state.count do
				items[i] = { id = POOL[i] }
			end

			Element("Frame", {
				id = "list",
				Size = UDim2.fromScale(1, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				LayoutOrder = 2,
			}, function()
				Element("UIListLayout", { Padding = UDim.new(0, px(4)) })

				TransitionList({
					items = items,
					preset = "collapseHeight",
					size = UDim2.new(1, 0, 0, px(30)),
				}, function(key, _item, removing)
					row(key, removing)
				end)
			end)
		end)
	end)
end)
