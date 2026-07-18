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

	-- Padding
	StyleRule(".p-xs::UIPadding", {
		PaddingTop = UDim.new(0, XS),
		PaddingBottom = UDim.new(0, XS),
		PaddingLeft = UDim.new(0, XS),
		PaddingRight = UDim.new(0, XS),
	})
	StyleRule(".p-sm::UIPadding", {
		PaddingTop = UDim.new(0, SM),
		PaddingBottom = UDim.new(0, SM),
		PaddingLeft = UDim.new(0, SM),
		PaddingRight = UDim.new(0, SM),
	})
	StyleRule(".p-md::UIPadding", {
		PaddingTop = UDim.new(0, MD),
		PaddingBottom = UDim.new(0, MD),
		PaddingLeft = UDim.new(0, MD),
		PaddingRight = UDim.new(0, MD),
	})
	StyleRule(".p-lg::UIPadding", {
		PaddingTop = UDim.new(0, XL),
		PaddingBottom = UDim.new(0, XL),
		PaddingLeft = UDim.new(0, XL),
		PaddingRight = UDim.new(0, XL),
	})

	-- Per-direction padding (priority 1 overrides general p-*)
	StyleRule(".pl-sm::UIPadding", { PaddingLeft = UDim.new(0, SM) }, nil, 1)
	StyleRule(".pl-md::UIPadding", { PaddingLeft = UDim.new(0, MD) }, nil, 1)
	StyleRule(".pl-lg::UIPadding", { PaddingLeft = UDim.new(0, XL) }, nil, 1)
	StyleRule(".pr-sm::UIPadding", { PaddingRight = UDim.new(0, SM) }, nil, 1)
	StyleRule(".pr-md::UIPadding", { PaddingRight = UDim.new(0, MD) }, nil, 1)
	StyleRule(".pr-lg::UIPadding", { PaddingRight = UDim.new(0, XL) }, nil, 1)
	StyleRule(".pt-sm::UIPadding", { PaddingTop = UDim.new(0, SM) }, nil, 1)
	StyleRule(".pt-md::UIPadding", { PaddingTop = UDim.new(0, MD) }, nil, 1)
	StyleRule(".pt-lg::UIPadding", { PaddingTop = UDim.new(0, XL) }, nil, 1)
	StyleRule(".pb-sm::UIPadding", { PaddingBottom = UDim.new(0, SM) }, nil, 1)
	StyleRule(".pb-md::UIPadding", { PaddingBottom = UDim.new(0, MD) }, nil, 1)
	StyleRule(".pb-lg::UIPadding", { PaddingBottom = UDim.new(0, XL) }, nil, 1)

	-- Direct forms — apply to an explicit UIPadding instance tagged with the class (mirrors
	-- the pseudo rules above, for when you create the UIPadding yourself).
	StyleRule(
		"UIPadding.p-xs",
		{ PaddingTop = UDim.new(0, XS), PaddingBottom = UDim.new(0, XS), PaddingLeft = UDim.new(0, XS), PaddingRight = UDim.new(0, XS) }
	)
	StyleRule(
		"UIPadding.p-sm",
		{ PaddingTop = UDim.new(0, SM), PaddingBottom = UDim.new(0, SM), PaddingLeft = UDim.new(0, SM), PaddingRight = UDim.new(0, SM) }
	)
	StyleRule(
		"UIPadding.p-md",
		{ PaddingTop = UDim.new(0, MD), PaddingBottom = UDim.new(0, MD), PaddingLeft = UDim.new(0, MD), PaddingRight = UDim.new(0, MD) }
	)
	StyleRule(
		"UIPadding.p-lg",
		{ PaddingTop = UDim.new(0, XL), PaddingBottom = UDim.new(0, XL), PaddingLeft = UDim.new(0, XL), PaddingRight = UDim.new(0, XL) }
	)

	StyleRule("UIPadding.pl-sm", { PaddingLeft = UDim.new(0, SM) }, nil, 1)
	StyleRule("UIPadding.pl-md", { PaddingLeft = UDim.new(0, MD) }, nil, 1)
	StyleRule("UIPadding.pl-lg", { PaddingLeft = UDim.new(0, XL) }, nil, 1)
	StyleRule("UIPadding.pr-sm", { PaddingRight = UDim.new(0, SM) }, nil, 1)
	StyleRule("UIPadding.pr-md", { PaddingRight = UDim.new(0, MD) }, nil, 1)
	StyleRule("UIPadding.pr-lg", { PaddingRight = UDim.new(0, XL) }, nil, 1)
	StyleRule("UIPadding.pt-sm", { PaddingTop = UDim.new(0, SM) }, nil, 1)
	StyleRule("UIPadding.pt-md", { PaddingTop = UDim.new(0, MD) }, nil, 1)
	StyleRule("UIPadding.pt-lg", { PaddingTop = UDim.new(0, XL) }, nil, 1)
	StyleRule("UIPadding.pb-sm", { PaddingBottom = UDim.new(0, SM) }, nil, 1)
	StyleRule("UIPadding.pb-md", { PaddingBottom = UDim.new(0, MD) }, nil, 1)
	StyleRule("UIPadding.pb-lg", { PaddingBottom = UDim.new(0, XL) }, nil, 1)

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
	StyleRule(".corner-lg::UICorner", { CornerRadius = R_XL })
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
