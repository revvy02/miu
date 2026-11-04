# miu
`miu` is a retained state library. The primary use case is for elegant immediate mode ui. You can write ui code declaratively by interleaving it directly in your ecs code. Immediate mode ui has overhead, but the overhead is explicit and easily visible.

## Basics

Node example (it's useful to have retained state that isn't necessarily an element, like for ui specific state)
```lua
RunService.Heartbeat:Connect(function()
	local node1 = Miu.push("outer_id")
	-- node2 should be the same reference across multiple frames
	local node2 = Miu.push("inner_id")

	Miu.pop()
	Miu.pop()
end)
```

Element push/pop example
```lua
Element.push("Frame", {
	id = "element_id",
	Size = UDim2.fromScale(1, 1),
	Transparency = 0.5,
})

Element.push("TextLabel", {
	-- id = "inner_text_label",
	-- it's best to have an explicit id, but leaving id nil gives it
	-- a numerical index based on the current scope. since current scope is
	-- inside the outer element, and nothing has been pushed yet, it will auto
	-- to an index of 1 (and will also name the TextLabel instance 1, based on the automatic cursor id)
	Text = "hi",
	Size = UDim2.fromScale(1, 1),
	TextSize = 30
})

Element.pop()
Element.pop() -- every element pop prunes that element's direct children that weren't visited this walk, unmounting their subtrees.
```

Further examples are going to just use the scope api directly, every push/pop can be represented as just a function call with the push/pop at the call stack boundaries. Below is an example equivalent to the one above with the scope/function syntax:
```lua
Element("Frame", {
	id = "element_id",
	Size = UDim2.fromScale(1, 1),
	Transparency = 0.5,
}, function() -- scope api just calls push/pop internally, and calls this render fn inside the push/pop
	Element("TextLabel", {
		-- no id again, like prev example
		Text = "hi",
		Size = UDim2.fromScale(1, 1),
		TextSize = 30
	}) -- only need to pass the render fn if you want a node inside for some reason
end)
```

Below is a full ui example using `Portal` to render ui in `PlayerGui`
```lua
local Miu = require("@pkg/miu")
local Element = Miu.Element
local Portal = Miu.Portal

local MiuTransition = require("@pkg/miu-transition")
local Activated = MiuTransition.Activated

local RunService = game:GetService("RunService")
local PlayerGui = game:GetService("Players").LocalPlayer.PlayerGui

RunService.Heartbeat:Connect(function()
	Portal(PlayerGui, "gui", function()
		Element("ScreenGui", {
			ResetOnSpawn = false,
			IgnoreGuiInset = false,
			DisplayOrder = 10,
			ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		}, function()
			local state = Miu("inner_state")

			if not state.score then
				state.score = 0
			end

			Element("TextButton", {
				Text = `score: {state.score}`,
				Size = UDim2.fromScale(1, 1),
				TextSize = 30
			}, function(node)
				-- if node.instance.GuiState == Enum.GuiState.Press then
					-- state.score += 1
				-- end

				-- You can read GuiState directly, but it stays Press every frame the button is
				-- held, so the check above counts one click many times. miu-transition's
				-- Activated helper only returns true on the first frame of each press.

				if Activated() then
					state.score += 1
				end
			end)
		end)
	end)
end)
```

## Examples of what's possible

Phone UI

https://github.com/user-attachments/assets/a01eb3f2-19fa-4db7-945e-4759d158c45f

Scope

https://github.com/user-attachments/assets/53598bd8-734c-4b59-8bf8-57403053c9a8
