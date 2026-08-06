local Element = require("../miu").Element
local MiuStory = require("../miu_ui_labs").MiuStory
local px = require("../miu_px").px

local Transition = require("./Transition")

local HEADER_COLOR = Color3.fromRGB(160, 160, 170)
local LABEL_COLOR = Color3.fromRGB(200, 200, 200)
local CARD_COLOR = Color3.fromRGB(45, 50, 65)

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

local function card(label)
	Element("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = CARD_COLOR,
		BackgroundTransparency = 0,
	}, function()
		Element("UICorner", { CornerRadius = UDim.new(0, px(8)) })
		Element("TextLabel", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Text = label,
			TextColor3 = LABEL_COLOR,
			TextSize = px(14),
		})
	end)
end

local function autoSizeContent()
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
end

return MiuStory({
	name = "Transition",
	summary = "Animated show/hide with position, transparency, and transform animations",
	controls = {
		show = true,
		nestedInnerShow = true,
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

		-- Direction + Transparency (default)
		Element("Frame", {
			Size = UDim2.new(1, 0, 0, px(140)),
			BackgroundTransparency = 1,
			ClipsDescendants = true,
		}, function()
			Element("UIListLayout", { Padding = UDim.new(0, px(8)) })

			header("Direction + Transparency (default)")

			Transition({
				id = "dir-trans",
				show = controls.show,
				size = UDim2.fromOffset(px(300), px(100)),
			}, function(visible)
				if visible then
					card("Slides and fades")
				end
			end)
		end)

		-- Presets: every named shape side by side, plus an explicit override
		Element("Frame", {
			Size = UDim2.new(1, 0, 0, px(240)),
			BackgroundTransparency = 1,
			ClipsDescendants = true,
		}, function()
			Element("UIListLayout", { Padding = UDim.new(0, px(8)) })

			header("Presets (explicit props override preset values)")

			Element("Frame", {
				Size = UDim2.new(1, 0, 0, px(200)),
				BackgroundTransparency = 1,
			}, function()
				Element("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					Wraps = true,
					Padding = UDim.new(0, px(8)),
				})

				for _, name in
					{ "slideDiagonal", "slideDown", "fade", "collapseHeight", "collapseWidth", "collapseBoth" }
				do
					Element("Frame", {
						id = `preset-slot-{name}`,
						Size = UDim2.fromOffset(px(150), px(90)),
						BackgroundTransparency = 1,
						ClipsDescendants = true,
					}, function()
						Transition({
							id = `preset-{name}`,
							show = controls.show,
							preset = name,
							size = UDim2.fromScale(1, 1),
						}, function(visible)
							if visible then
								card(name)
							end
						end)
					end)
				end

				-- Explicit prop wins over the preset's direction
				Element("Frame", {
					id = "preset-slot-override",
					Size = UDim2.fromOffset(px(150), px(90)),
					BackgroundTransparency = 1,
					ClipsDescendants = true,
				}, function()
					Transition({
						id = "preset-override",
						show = controls.show,
						preset = "slideDown",
						animateInDirection = UDim2.fromScale(0.5, -0.5),
						size = UDim2.fromScale(1, 1),
					}, function(visible)
						if visible then
							card("slideDown\n+ override")
						end
					end)
				end)
			end)
		end)

		-- Transparency only
		Element("Frame", {
			Size = UDim2.new(1, 0, 0, px(140)),
			BackgroundTransparency = 1,
		}, function()
			Element("UIListLayout", { Padding = UDim.new(0, px(8)) })

			header("Transparency only")

			Transition({
				id = "trans-only",
				show = controls.show,
				size = UDim2.fromOffset(px(300), px(100)),
				animateDirection = false,
			}, function(visible)
				if visible then
					card("Fades in place")
				end
			end)
		end)

		-- Direction only
		Element("Frame", {
			Size = UDim2.new(1, 0, 0, px(140)),
			BackgroundTransparency = 1,
			ClipsDescendants = true,
		}, function()
			Element("UIListLayout", { Padding = UDim.new(0, px(8)) })

			header("Direction only")

			Transition({
				id = "dir-only",
				show = controls.show,
				size = UDim2.fromOffset(px(300), px(100)),
				animateTransparency = false,
			}, function(visible)
				if visible then
					card("Slides without fading")
				end
			end)
		end)

		-- Width transform
		Element("Frame", {
			Size = UDim2.new(1, 0, 0, px(140)),
			BackgroundTransparency = 1,
		}, function()
			Element("UIListLayout", { Padding = UDim.new(0, px(8)) })

			header("Width transform")

			Transition({
				id = "width-tf",
				show = controls.show,
				size = UDim2.fromOffset(px(300), px(100)),
				animateDirection = false,
				animateWidthTransform = true,
				clipsDescendants = true,
			}, function(visible)
				if visible then
					card("Shrinks horizontally")
				end
			end)
		end)

		-- Height transform
		Element("Frame", {
			Size = UDim2.new(1, 0, 0, px(140)),
			BackgroundTransparency = 1,
		}, function()
			Element("UIListLayout", { Padding = UDim.new(0, px(8)) })

			header("Height transform")

			Transition({
				id = "height-tf",
				show = controls.show,
				size = UDim2.fromOffset(px(300), px(100)),
				animateDirection = false,
				animateHeightTransform = true,
				clipsDescendants = true,
			}, function(visible)
				if visible then
					card("Shrinks vertically")
				end
			end)
		end)

		-- Both transforms
		Element("Frame", {
			Size = UDim2.new(1, 0, 0, px(140)),
			BackgroundTransparency = 1,
		}, function()
			Element("UIListLayout", { Padding = UDim.new(0, px(8)) })

			header("Both transforms")

			Transition({
				id = "both-tf",
				show = controls.show,
				size = UDim2.fromOffset(px(300), px(100)),
				animateDirection = false,
				animateWidthTransform = true,
				animateHeightTransform = true,
				clipsDescendants = true,
			}, function(visible)
				if visible then
					card("Shrinks both axes")
				end
			end)
		end)

		-- AutomaticSize.Y
		Element("Frame", {
			Size = UDim2.fromScale(1, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			ClipsDescendants = true,
		}, function()
			Element("UIListLayout", { Padding = UDim.new(0, px(8)) })

			header("AutomaticSize.Y — height from content")

			Transition({
				id = "auto-y",
				show = controls.show,
				size = UDim2.fromOffset(px(250), 0),
				automaticSize = Enum.AutomaticSize.Y,
				backgroundColor3 = CARD_COLOR,
				backgroundTransparency = 0,
			}, function(visible)
				if visible then
					autoSizeContent()
				end
			end)
		end)

		-- Nested transitions
		Element("Frame", {
			Size = UDim2.new(1, 0, 0, px(200)),
			BackgroundTransparency = 1,
			ClipsDescendants = true,
		}, function()
			Element("UIListLayout", { Padding = UDim.new(0, px(8)) })

			header("Nested — outer contains inner transitions")

			Transition({
				id = "nested-outer",
				show = controls.show,
				size = UDim2.fromOffset(px(400), px(140)),
				automaticSize = Enum.AutomaticSize.XY,
				clipsDescendants = true,
			}, function(outerVisible)
				if outerVisible then
					Element("Frame", {
						Size = UDim2.fromScale(1, 1),
						BackgroundColor3 = Color3.fromRGB(35, 38, 48),
						BackgroundTransparency = 0,
					}, function()
						Element("UICorner", { CornerRadius = UDim.new(0, px(8)) })
						Element("UIListLayout", {
							FillDirection = Enum.FillDirection.Horizontal,
							Padding = UDim.new(0, px(8)),
							HorizontalAlignment = Enum.HorizontalAlignment.Center,
							VerticalAlignment = Enum.VerticalAlignment.Center,
						})
						Element("UIPadding", {
							PaddingLeft = UDim.new(0, px(12)),
							PaddingRight = UDim.new(0, px(12)),
						})

						local innerColors = {
							Color3.fromRGB(180, 80, 80),
							Color3.fromRGB(80, 160, 80),
							Color3.fromRGB(80, 100, 200),
						}

						for i, color in innerColors do
							Transition({
								id = `inner-{i}`,
								show = controls.show,
								size = UDim2.fromOffset(px(100), px(80)),
								animateDirection = false,
								animateWidthTransform = true,
								animateHeightTransform = true,
								clipsDescendants = true,
							}, function(innerVisible)
								if innerVisible then
									Element("Frame", {
										Size = UDim2.fromScale(1, 1),
										BackgroundColor3 = color,
										BackgroundTransparency = 0,
									}, function()
										Element("UICorner", { CornerRadius = UDim.new(0, px(6)) })
										Element("TextLabel", {
											Size = UDim2.fromScale(1, 1),
											BackgroundTransparency = 1,
											Text = `Inner {i}`,
											TextColor3 = Color3.new(1, 1, 1),
											TextSize = px(13),
											FontFace = Font.new(
												"rbxasset://fonts/families/GothamSSm.json",
												Enum.FontWeight.Bold
											),
										})
									end)
								end
							end)
						end
					end)
				end
			end)
		end)

		-- Nested + AutomaticSize: the outer's measured height tracks the inner's
		-- animation LIVE. The outer is auto-sized over its content; the inner is an
		-- auto-sized collapseHeight Transition on its own toggle. While the inner
		-- grows/collapses (its container height animating every frame), the outer's
		-- measurement follows it through the canvas layers — auto chains propagate
		-- through scale-sized frames fine (probe-verified).
		Element("Frame", {
			Size = UDim2.fromScale(1, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
		}, function()
			Element("UIListLayout", { Padding = UDim.new(0, px(8)) })

			header("Nested + AutomaticSize.Y — outer measures the inner's animation (nestedInnerShow)")

			Transition({
				id = "nested-auto-outer",
				show = controls.show,
				size = UDim2.fromOffset(px(280), 0),
				automaticSize = Enum.AutomaticSize.Y,
				backgroundColor3 = Color3.fromRGB(35, 38, 48),
				backgroundTransparency = 0,
			}, function(outerVisible)
				if not outerVisible then
					return
				end

				Element("UIListLayout", { Padding = UDim.new(0, px(6)) })
				Element("UIPadding", {
					PaddingTop = UDim.new(0, px(8)),
					PaddingBottom = UDim.new(0, px(8)),
					PaddingLeft = UDim.new(0, px(8)),
					PaddingRight = UDim.new(0, px(8)),
				})

				Element("TextLabel", {
					id = "static",
					Size = UDim2.new(1, 0, 0, px(20)),
					BackgroundTransparency = 1,
					Text = "Static line (always here)",
					TextColor3 = LABEL_COLOR,
					TextSize = px(14),
					LayoutOrder = 1,
				})

				Transition({
					id = "nested-auto-inner",
					show = controls.nestedInnerShow,
					preset = "collapseHeight",
					size = UDim2.fromScale(1, 0),
					automaticSize = Enum.AutomaticSize.Y,
					backgroundColor3 = Color3.fromRGB(60, 50, 80),
					backgroundTransparency = 0,
					layoutOrder = 2,
					clipsDescendants = true,
				}, function(innerVisible)
					if innerVisible then
						autoSizeContent()
					end
				end)

				Element("TextLabel", {
					id = "trailing",
					Size = UDim2.new(1, 0, 0, px(20)),
					BackgroundTransparency = 1,
					Text = "Trailing line (rides the reflow)",
					TextColor3 = LABEL_COLOR,
					TextSize = px(14),
					LayoutOrder = 3,
				})
			end)
		end)
	end)
end)
