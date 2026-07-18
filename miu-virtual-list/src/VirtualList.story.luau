local UILabs = require(script.Parent.Parent.ui_labs)

local Miu = require(script.Parent.Parent.miu)
local Instance = Miu.Instance
local MiuStory = require(script.Parent.Parent.miu_ui_labs).MiuStory
local px = require(script.Parent.Parent.miu_px).px

local MiuVirtualList = require(script.Parent)
local VirtualList = MiuVirtualList.VirtualList
local Dimensions = MiuVirtualList.Dimensions

local COLORS = {
	Color3.fromRGB(40, 45, 60),
	Color3.fromRGB(35, 50, 55),
	Color3.fromRGB(50, 40, 55),
	Color3.fromRGB(45, 55, 40),
}

return MiuStory({
	name = "VirtualList",
	summary = "Virtualized scrolling list/grid — only renders visible items",
	controls = {
		itemCount = UILabs.Slider(1000, 10, 10000, 10),
		itemHeight = UILabs.Slider(40, 20, 100, 5),
		spacing = UILabs.Slider(0, 0, 20, 1),
		mode = UILabs.Choose({ "list", "grid" }, 1),
		direction = UILabs.Choose({ "y", "x" }, 1),
	},
}, function(controls)
	-- Generate synthetic data
	local data = table.create(controls.itemCount)
	for i = 1, controls.itemCount do
		data[i] = { index = i }
	end

	-- Build dimensions based on mode
	local dims
	if controls.mode == "grid" then
		dims = Dimensions.consistentUDim2(UDim2.fromOffset(px(controls.itemHeight * 2.5), px(controls.itemHeight)))
	else
		dims = Dimensions.consistentSize(px(controls.itemHeight))
	end

	if controls.spacing > 0 then
		dims = Dimensions.withSpacing(dims, px(controls.spacing))
	end

	Instance("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(20, 20, 30),
	}, function()
		VirtualList({
			data = data,
			dimensions = dims,
			direction = controls.direction,
		}, function(item, index)
			Instance("Frame", {
				Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = COLORS[(index - 1) % #COLORS + 1],
			}, function()
				Instance("TextLabel", {
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					Text = `Item {item.index}`,
					TextColor3 = Color3.fromRGB(200, 200, 200),
					Font = Enum.Font.RobotoMono,
					TextSize = px(12),
				})
			end)
		end)
	end)
end)
