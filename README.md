# miu
`miu` is a retained state library. The primary use case is for elegant immediate mode ui. You can write ui code declaratively by interleaving it directly in your ecs code. Immediate mode ui has overhead, but the overhead is explicit and easily visible.

## Installation

Install it with [Wally](https://wally.run/package/revvy02/miu?version=0.4.3) by adding it to your `wally.toml`:

```toml
[dependencies]
miu = "revvy02/miu@0.4.3"
```

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

## API

### `Miu(id?, fn?)`

Enters the child node `id` of the current node, creating it on first visit, then runs `fn(node)` inside it and returns the node. Anything you store on a node lasts across calls:

```lua
local state = Miu("counter")
state.count = (state.count or 0) + 1
```

Leave out `id` and the node takes the next position in the current scope. Give an explicit id to any node that's conditional or inside a loop, or state can move between nodes when a branch flips.

`Miu.push(id?)` / `Miu.pop()` are the bracket form, and `Miu.peek()` returns the current node. Plain nodes never remove unvisited children; only `Element` and `Portal` do.

`Miu.defer(fn)` runs `fn` when the current scope pops, after all its siblings have rendered.

### `Element(className, props?, fn?)`

Creates a `className` Instance on first visit, parents it to the nearest enclosing Element or Portal, and applies `props`. Props are the Instance's own properties, plus:

- `id`: the node's id (a string or number)
- `tags`: CollectionService tags
- `attributes`: a table of attributes
- `events`: `{ [signalName] = handler }`. Handlers can be inline closures.

A prop is only applied when its value changes, and a prop you stop passing keeps its last value.

`fn(node)` renders children, and `node.instance` is the Instance. When the call returns, any direct child that wasn't visited during it is removed. `Element.push` / `Element.pop` are the bracket form.

### `Portal(target, id, fn?)`

Renders `fn`'s elements into an existing Instance, such as `PlayerGui`. Like `Element`, it removes children it didn't visit when it returns, and it never changes `target` itself. A Portal you stop calling stays mounted, so to remove its contents, put the condition inside it:

```lua
Portal(playerGui, "hud", function()
	if showHud then
		Element("ScreenGui", { ResetOnSpawn = false })
	end
end)
```

### `Context(default)`

Passes a value down the tree without threading it through props. `Ctx(value, fn)` provides `value` to everything called inside `fn`, and `Ctx()` reads the nearest value provided, or `default`:

```lua
local Theme = Miu.Context({ text = Color3.new(1, 1, 1) })

Theme({ text = Color3.new(1, 0.4, 0.4) }, function()
	Element("TextLabel", { Text = "warning", TextColor3 = Theme().text })
end)
```

### `DeltaTime(id?)`

Returns the seconds since this call site last ran, or 0 on its first run. Each call site is timed on its own, so a subtree you render less often still gets the real elapsed time:

```lua
local spin = Miu("spin")
spin.angle = (spin.angle or 0) + 90 * DeltaTime()
```

Give it an `id` when the call is conditional.

### `Smooth(goal, rate?, id?)`

Eases toward `goal` and returns the current value, at the same speed whatever the framerate. It works with numbers and anything with a `:Lerp` method, such as `Color3`, `UDim2`, `Vector3` and `CFrame`. `rate` defaults to 12, and higher is snappier:

```lua
Element("Frame", {
	Size = UDim2.fromScale(Smooth(if open then 1 else 0, 16, "width"), 1),
})
```

Give it an `id` when the call is conditional, inside a loop, or one of several `Smooth` calls in the same props table.

## Examples of what's possible

Phone UI

https://github.com/user-attachments/assets/a01eb3f2-19fa-4db7-945e-4759d158c45f

Scope

https://github.com/user-attachments/assets/53598bd8-734c-4b59-8bf8-57403053c9a8
