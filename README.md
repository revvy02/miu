
miu is a retained state library. Primary use case is for elegant immediate mode ui. You can write ui code declaratively by interleaving it directly in your ecs code. Immediate mode ui has overhead, but the overhead is explicit and easily visible, and miu is also faster than things like iris that depend on `debug.info`.

Miu node example (it's useful to need retained state that isn't necessarily an element)
```lua
RunService.Heartbeat:Connect(function()
	local node1 = Miu.push("outer_id")
	 -- node2 should be the same reference across multiple frames
	local node2 = Miu.push("inner_id")
	
	Miu.pop()
	Miu.pop()
end)
```

`Element` is the analog to React.createElement:
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
	TextSize = 30 -- lowkey forgot if this is even the right property
})

Element.pop() 
Element.pop() -- every element pop call scans the current retained tree, any unvisited element is pruned and cleaned up.
```

further examples are going to just use the scope api directly, every push/pop can be represented as just a function call with the push/pop at the call stack boundaries. below is an example equivalent to the one above with the scope/function syntax:
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

ugly native leaderboard ui example
```lua
-- once again explicit ids are good to avoid the footgun but im lazy and like
-- minimal code, even if it means i may have to think more later. if you have subtrees that render conditionally then explicit ids avoid problems like nodes going to the wrong callers

-- portal component will render its inner element tree in the portal location,
-- this is the analog to React.createPortal
Portal("leaderboard", localPlayer.PlayerGui, function()
	Element("ScreenGui", {
		ResetOnSpawn = false,
		IgnoreGuiInset = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}, function()
	Element("Frame", {
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(0, 0),
	}, function()
		Element("UIListLayout", {
			-- props for vertical layout
		})
		for e, player, score in world:query(cts.Player, cts.Score) do
			Element("Frame", {
				AutomaticSize = Enum.AutomaticSize.XY,
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(0, 0),
			}, function()
				Element("UIListLayout", {
					-- props for horizontal layout
				})
				Element("TextLabel", {
					Text = player.Name,
					TextSize = 20,
					AutomaticSize = Enum.AutomaticSize.XY
				})
				Element("TextLabel", {
					Text = tostring(score)
					TextSize = 20,
					AutomaticSize = Enum.AutomaticSize.XY
				})
			end)
		end
	end)
end)
```

-- examples of more complicated ui coming soon