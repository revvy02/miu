local StyleRule = require("./StyleRule")

local px = require("../miu_px").px

return function()
	-- Spacing scale (px() is viewport-scaled and re-evaluated each rebuild, so
	-- these are computed per call, not hoisted to module scope).
	local XS = px(1)
	local SM = px(4)
	local MD = px(8)
	local LG = px(12)
	local XL = px(16)

	StyleRule("Frame", { BorderSizePixel = 0 })
	StyleRule("TextButton", { BorderSizePixel = 0 })

	-- Background / text
	StyleRule(".bg-none", { BackgroundTransparency = 1 })
	StyleRule(".text-base", { BackgroundTransparency = 1, TextColor3 = Color3.new(1, 1, 1) })

	StyleRule(".clip", { ClipsDescendants = true })

	-- FlexItem
	StyleRule(".flex-mode-fill::UIFlexItem", { FlexMode = Enum.UIFlexMode.Fill })
	StyleRule(".flex-mode-grow::UIFlexItem", { FlexMode = Enum.UIFlexMode.Grow })
	StyleRule(".flex-mode-shrink::UIFlexItem", { FlexMode = Enum.UIFlexMode.Shrink })

	-- Sizing
	StyleRule(".auto-size", { Size = UDim2.fromScale(0, 0), AutomaticSize = Enum.AutomaticSize.XY })
	StyleRule(".auto-size-x", { Size = UDim2.fromScale(0, 1), AutomaticSize = Enum.AutomaticSize.X })
	StyleRule(".auto-size-y", { Size = UDim2.fromScale(1, 0), AutomaticSize = Enum.AutomaticSize.Y })
	StyleRule("ScrollingFrame", { CanvasSize = UDim2.new() })
	StyleRule("ScrollingFrame.auto-canvas-size", { Size = UDim2.fromScale(0, 0), AutomaticCanvasSize = Enum.AutomaticSize.XY })
	StyleRule("ScrollingFrame.auto-canvas-size-x", { Size = UDim2.fromScale(0, 1), AutomaticCanvasSize = Enum.AutomaticSize.X })
	StyleRule("ScrollingFrame.auto-canvas-size-y", { Size = UDim2.fromScale(1, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y })

	-- Layout (pseudo-instance — on tagged Frames)
	StyleRule(".flex-col::UIListLayout", { FillDirection = Enum.FillDirection.Vertical, SortOrder = Enum.SortOrder.LayoutOrder })
	StyleRule(".flex-row::UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder })
	StyleRule(".flex-wrap::UIListLayout", { Wraps = true })

	StyleRule(".h-left::UIListLayout", { HorizontalAlignment = Enum.HorizontalAlignment.Left })
	StyleRule(".h-center::UIListLayout", { HorizontalAlignment = Enum.HorizontalAlignment.Center })
	StyleRule(".h-right::UIListLayout", { HorizontalAlignment = Enum.HorizontalAlignment.Right })
	StyleRule(".h-flex-between::UIListLayout", { HorizontalFlex = Enum.UIFlexAlignment.SpaceBetween })
	StyleRule(".h-flex-even::UIListLayout", { HorizontalFlex = Enum.UIFlexAlignment.SpaceEvenly })
	StyleRule(".h-flex-around::UIListLayout", { HorizontalFlex = Enum.UIFlexAlignment.SpaceAround })

	StyleRule(".v-top::UIListLayout", { VerticalAlignment = Enum.VerticalAlignment.Top })
	StyleRule(".v-center::UIListLayout", { VerticalAlignment = Enum.VerticalAlignment.Center })
	StyleRule(".v-bottom::UIListLayout", { VerticalAlignment = Enum.VerticalAlignment.Bottom })
	StyleRule(".v-flex-between::UIListLayout", { VerticalFlex = Enum.UIFlexAlignment.SpaceBetween })
	StyleRule(".v-flex-even::UIListLayout", { VerticalFlex = Enum.UIFlexAlignment.SpaceEvenly })
	StyleRule(".v-flex-around::UIListLayout", { VerticalFlex = Enum.UIFlexAlignment.SpaceAround })

	StyleRule(".gap-xs::UIListLayout", { Padding = UDim.new(0, XS) })
	StyleRule(".gap-sm::UIListLayout", { Padding = UDim.new(0, SM) })
	StyleRule(".gap-md::UIListLayout", { Padding = UDim.new(0, MD) })
	StyleRule(".gap-lg::UIListLayout", { Padding = UDim.new(0, LG) })
	StyleRule(".gap-xl::UIListLayout", { Padding = UDim.new(0, XL) })

	-- Layout (direct — on explicit UIListLayout instances)
	StyleRule("UIListLayout.flex-col", { FillDirection = Enum.FillDirection.Vertical, SortOrder = Enum.SortOrder.LayoutOrder })
	StyleRule("UIListLayout.flex-row", { FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder })
	StyleRule("UIListLayout.flex-wrap", { Wraps = true })
	StyleRule("UIListLayout.h-left", { HorizontalAlignment = Enum.HorizontalAlignment.Left })
	StyleRule("UIListLayout.h-center", { HorizontalAlignment = Enum.HorizontalAlignment.Center })
	StyleRule("UIListLayout.h-right", { HorizontalAlignment = Enum.HorizontalAlignment.Right })
	StyleRule("UIListLayout.v-top", { VerticalAlignment = Enum.VerticalAlignment.Top })
	StyleRule("UIListLayout.v-center", { VerticalAlignment = Enum.VerticalAlignment.Center })
	StyleRule("UIListLayout.v-bottom", { VerticalAlignment = Enum.VerticalAlignment.Bottom })
	StyleRule("UIListLayout.gap-xs", { Padding = UDim.new(0, XS) })
	StyleRule("UIListLayout.gap-sm", { Padding = UDim.new(0, SM) })
	StyleRule("UIListLayout.gap-md", { Padding = UDim.new(0, MD) })
	StyleRule("UIListLayout.gap-lg", { Padding = UDim.new(0, LG) })
	StyleRule("UIListLayout.gap-xl", { Padding = UDim.new(0, XL) })

	StyleRule("Frame", { BorderSizePixel = 0 })
	StyleRule("ScrollingFrame", { BorderSizePixel = 0, ScrollBarThickness = SM, ScrollBarImageTransparency = 0.8 })

	StyleRule(".group", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1) })
	StyleRule(".frame", { BackgroundTransparency = 0, Size = UDim2.new() })

	-- Padding. Same step table as gap-*: xs=1 sm=4 md=8 lg=12 xl=16.
	-- Arrays, not maps: StyleRule nodes are auto-cursor keyed, so emission order must
	-- be the same every rebuild.
	local STEPS = { { "xs", XS }, { "sm", SM }, { "md", MD }, { "lg", LG }, { "xl", XL } }
	local EDGES = { { "l", "PaddingLeft" }, { "r", "PaddingRight" }, { "t", "PaddingTop" }, { "b", "PaddingBottom" } }
	for _, stepEntry in STEPS do
		local step, size = stepEntry[1], stepEntry[2]
		local v = UDim.new(0, size)
		local all = { PaddingTop = v, PaddingBottom = v, PaddingLeft = v, PaddingRight = v }
		-- Pseudo form (on the tagged GuiObject) and direct form (on an explicit UIPadding).
		StyleRule(`.p-{step}::UIPadding`, all)
		StyleRule(`UIPadding.p-{step}`, all)
		-- Per-edge (priority 1 overrides general p-*)
		for _, edgeEntry in EDGES do
			local edge, prop = edgeEntry[1], edgeEntry[2]
			StyleRule(`.p{edge}-{step}::UIPadding`, { [prop] = v }, nil, 1)
			StyleRule(`UIPadding.p{edge}-{step}`, { [prop] = v }, nil, 1)
		end
	end

	-- Corner radii. UICorner defaults every corner to CornerRadius (0, 8), so a
	-- per-corner preset must set ALL FOUR corners (named = radius, rest = ZERO) —
	-- any corner left unset would round to 8 instead of staying square.
	local ZERO = UDim.new(0, 0)
	local R_SM = UDim.new(0, SM)
	local R_MD = UDim.new(0, MD)
	local R_LG = UDim.new(0, LG)
	local R_XL = UDim.new(0, XL)
	local R_FULL = UDim.new(1, 0)

	StyleRule(".corner-sm::UICorner", { CornerRadius = R_SM })
	StyleRule(".corner-md::UICorner", { CornerRadius = R_MD })
	StyleRule(".corner-lg::UICorner", { CornerRadius = R_LG })
	StyleRule(".corner-xl::UICorner", { CornerRadius = R_XL })
	StyleRule(".corner-full::UICorner", { CornerRadius = R_FULL })

	-- Per-edge (t/b/l/r) and per-corner (tl/tr/bl/br) radii at each size; every
	-- rule fully defines all four corners (named = radius, rest = ZERO) so the
	-- unset corners stay square rather than falling back to the default radius.
	StyleRule(".corner-t-sm::UICorner", { TopLeftRadius = R_SM, TopRightRadius = R_SM, BottomLeftRadius = ZERO, BottomRightRadius = ZERO })
	StyleRule(".corner-b-sm::UICorner", { TopLeftRadius = ZERO, TopRightRadius = ZERO, BottomLeftRadius = R_SM, BottomRightRadius = R_SM })
	StyleRule(".corner-l-sm::UICorner", { TopLeftRadius = R_SM, TopRightRadius = ZERO, BottomLeftRadius = R_SM, BottomRightRadius = ZERO })
	StyleRule(".corner-r-sm::UICorner", { TopLeftRadius = ZERO, TopRightRadius = R_SM, BottomLeftRadius = ZERO, BottomRightRadius = R_SM })
	StyleRule(".corner-tl-sm::UICorner", { TopLeftRadius = R_SM, TopRightRadius = ZERO, BottomLeftRadius = ZERO, BottomRightRadius = ZERO })
	StyleRule(".corner-tr-sm::UICorner", { TopLeftRadius = ZERO, TopRightRadius = R_SM, BottomLeftRadius = ZERO, BottomRightRadius = ZERO })
	StyleRule(".corner-bl-sm::UICorner", { TopLeftRadius = ZERO, TopRightRadius = ZERO, BottomLeftRadius = R_SM, BottomRightRadius = ZERO })
	StyleRule(".corner-br-sm::UICorner", { TopLeftRadius = ZERO, TopRightRadius = ZERO, BottomLeftRadius = ZERO, BottomRightRadius = R_SM })

	StyleRule(".corner-t-md::UICorner", { TopLeftRadius = R_MD, TopRightRadius = R_MD, BottomLeftRadius = ZERO, BottomRightRadius = ZERO })
	StyleRule(".corner-b-md::UICorner", { TopLeftRadius = ZERO, TopRightRadius = ZERO, BottomLeftRadius = R_MD, BottomRightRadius = R_MD })
	StyleRule(".corner-l-md::UICorner", { TopLeftRadius = R_MD, TopRightRadius = ZERO, BottomLeftRadius = R_MD, BottomRightRadius = ZERO })
	StyleRule(".corner-r-md::UICorner", { TopLeftRadius = ZERO, TopRightRadius = R_MD, BottomLeftRadius = ZERO, BottomRightRadius = R_MD })
	StyleRule(".corner-tl-md::UICorner", { TopLeftRadius = R_MD, TopRightRadius = ZERO, BottomLeftRadius = ZERO, BottomRightRadius = ZERO })
	StyleRule(".corner-tr-md::UICorner", { TopLeftRadius = ZERO, TopRightRadius = R_MD, BottomLeftRadius = ZERO, BottomRightRadius = ZERO })
	StyleRule(".corner-bl-md::UICorner", { TopLeftRadius = ZERO, TopRightRadius = ZERO, BottomLeftRadius = R_MD, BottomRightRadius = ZERO })
	StyleRule(".corner-br-md::UICorner", { TopLeftRadius = ZERO, TopRightRadius = ZERO, BottomLeftRadius = ZERO, BottomRightRadius = R_MD })

	StyleRule(".corner-t-lg::UICorner", { TopLeftRadius = R_LG, TopRightRadius = R_LG, BottomLeftRadius = ZERO, BottomRightRadius = ZERO })
	StyleRule(".corner-b-lg::UICorner", { TopLeftRadius = ZERO, TopRightRadius = ZERO, BottomLeftRadius = R_LG, BottomRightRadius = R_LG })
	StyleRule(".corner-l-lg::UICorner", { TopLeftRadius = R_LG, TopRightRadius = ZERO, BottomLeftRadius = R_LG, BottomRightRadius = ZERO })
	StyleRule(".corner-r-lg::UICorner", { TopLeftRadius = ZERO, TopRightRadius = R_LG, BottomLeftRadius = ZERO, BottomRightRadius = R_LG })
	StyleRule(".corner-tl-lg::UICorner", { TopLeftRadius = R_LG, TopRightRadius = ZERO, BottomLeftRadius = ZERO, BottomRightRadius = ZERO })
	StyleRule(".corner-tr-lg::UICorner", { TopLeftRadius = ZERO, TopRightRadius = R_LG, BottomLeftRadius = ZERO, BottomRightRadius = ZERO })
	StyleRule(".corner-bl-lg::UICorner", { TopLeftRadius = ZERO, TopRightRadius = ZERO, BottomLeftRadius = R_LG, BottomRightRadius = ZERO })
	StyleRule(".corner-br-lg::UICorner", { TopLeftRadius = ZERO, TopRightRadius = ZERO, BottomLeftRadius = ZERO, BottomRightRadius = R_LG })

	StyleRule(".corner-t-xl::UICorner", { TopLeftRadius = R_XL, TopRightRadius = R_XL, BottomLeftRadius = ZERO, BottomRightRadius = ZERO })
	StyleRule(".corner-b-xl::UICorner", { TopLeftRadius = ZERO, TopRightRadius = ZERO, BottomLeftRadius = R_XL, BottomRightRadius = R_XL })
	StyleRule(".corner-l-xl::UICorner", { TopLeftRadius = R_XL, TopRightRadius = ZERO, BottomLeftRadius = R_XL, BottomRightRadius = ZERO })
	StyleRule(".corner-r-xl::UICorner", { TopLeftRadius = ZERO, TopRightRadius = R_XL, BottomLeftRadius = ZERO, BottomRightRadius = R_XL })
	StyleRule(".corner-tl-xl::UICorner", { TopLeftRadius = R_XL, TopRightRadius = ZERO, BottomLeftRadius = ZERO, BottomRightRadius = ZERO })
	StyleRule(".corner-tr-xl::UICorner", { TopLeftRadius = ZERO, TopRightRadius = R_XL, BottomLeftRadius = ZERO, BottomRightRadius = ZERO })
	StyleRule(".corner-bl-xl::UICorner", { TopLeftRadius = ZERO, TopRightRadius = ZERO, BottomLeftRadius = R_XL, BottomRightRadius = ZERO })
	StyleRule(".corner-br-xl::UICorner", { TopLeftRadius = ZERO, TopRightRadius = ZERO, BottomLeftRadius = ZERO, BottomRightRadius = R_XL })

	StyleRule(".corner-t-full::UICorner", { TopLeftRadius = R_FULL, TopRightRadius = R_FULL, BottomLeftRadius = ZERO, BottomRightRadius = ZERO })
	StyleRule(".corner-b-full::UICorner", { TopLeftRadius = ZERO, TopRightRadius = ZERO, BottomLeftRadius = R_FULL, BottomRightRadius = R_FULL })
	StyleRule(".corner-l-full::UICorner", { TopLeftRadius = R_FULL, TopRightRadius = ZERO, BottomLeftRadius = R_FULL, BottomRightRadius = ZERO })
	StyleRule(".corner-r-full::UICorner", { TopLeftRadius = ZERO, TopRightRadius = R_FULL, BottomLeftRadius = ZERO, BottomRightRadius = R_FULL })
	StyleRule(".corner-tl-full::UICorner", { TopLeftRadius = R_FULL, TopRightRadius = ZERO, BottomLeftRadius = ZERO, BottomRightRadius = ZERO })
	StyleRule(".corner-tr-full::UICorner", { TopLeftRadius = ZERO, TopRightRadius = R_FULL, BottomLeftRadius = ZERO, BottomRightRadius = ZERO })
	StyleRule(".corner-bl-full::UICorner", { TopLeftRadius = ZERO, TopRightRadius = ZERO, BottomLeftRadius = R_FULL, BottomRightRadius = ZERO })
	StyleRule(".corner-br-full::UICorner", { TopLeftRadius = ZERO, TopRightRadius = ZERO, BottomLeftRadius = ZERO, BottomRightRadius = R_FULL })

	StyleRule(".outline-dark::UIStroke", {
		Thickness = XS,
		Transparency = 0.8,
		Color = Color3.fromRGB(0, 0, 0),
		BorderStrokePosition = Enum.BorderStrokePosition.Inner,
	})
	StyleRule(".outline-light::UIStroke", {
		Thickness = XS,
		Transparency = 0.8,
		Color = Color3.fromRGB(255, 255, 255),
		BorderStrokePosition = Enum.BorderStrokePosition.Inner,
	})
end
