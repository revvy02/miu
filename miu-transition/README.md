# miu-transition

## Smooth

Framerate-independent easing toward a goal, one call per frame:

```lua
local Smooth = require("@pkg/miu_transition").Smooth

-- somewhere inside a miu scope, every frame:
Element("Frame", {
	Size = Smooth(if hovering then UDim2.fromScale(1.1, 1.1) else UDim2.fromScale(1, 1), 8, "size"),
	BackgroundColor3 = Smooth(if selected then SELECTED_COLOR else IDLE_COLOR, 12, "color"),
})
```

```lua
Smooth(goal, rate?, id?) -> value
```

- `goal` — where to ease to. Works with numbers and any `:Lerp`-able type (Color3, UDim2, Vector2/3, CFrame, …); every type animates identically.
- `rate` — how fast to ease, default `12`. Higher is snappier. Framerate-independent, critically damped feel — no overshoot.
- `id` — optional. Without one the state is keyed by call order in the enclosing scope. Pass an id whenever that order isn't fixed: a conditional call, a call in a loop, or sibling `Smooth` calls inside one props table — reordering two of them would silently swap their state.

The value starts at the first goal it sees — nothing pops in from zero.

## Transition

Animated show/hide — slide, fade, and collapse, driven by a single `show` boolean:

```lua
local Transition = require("@pkg/miu_transition").Transition

Transition({
	id = "tooltip",
	show = state.open,
	size = UDim2.fromOffset(200, 120),
}, function(visible)
	if visible then
		Element("TextLabel", { Text = "Hello" })
	end
end)
```

```lua
Transition(props, fn) -> visible
```

`fn(visible)` renders the content. `visible` is `false` only once the hide animation has fully finished — use it to skip rendering children while fully hidden. The call also returns `visible`, useful for chaining (`local anyOpen = Transition(...)`).

Flipping `show` mid-flight retargets immediately — a half-open panel closes from where it is.

### Presets

`preset` names a common animation shape. Any explicitly passed prop overrides the preset's value (explicit prop > preset > default). Unknown preset names error.

| preset | shape |
|---|---|
| `slideDiagonal` | diagonal slide + fade (same as the built-in defaults) |
| `slideDown` | vertical reveal in place + fade (dropdowns, panels) |
| `fade` | fade in place, no motion (overlays) |
| `collapseHeight` | fade + height shrink, no slide (list rows, collapsibles) |
| `collapseWidth` | fade + width shrink, no slide |
| `collapseBoth` | fade + both-axis shrink, no slide (2D grids) |

```lua
Transition({ id = "dropdown", show = open, preset = "slideDown", size = size }, function(visible)
	if visible then
		renderOptions()
	end
end)
```

### Props

Animation:

- `show: boolean` — target state.
- `preset: string?` — see above.
- `decay: number?` — easing rate, default `12`.
- `animateDirection: boolean?` (default `true`), `animateInDirection` / `animateOutDirection: UDim2?` — slide vector for enter/exit, in fractions of the container (default diagonal).
- `animateTransparency: boolean?` — fade the content as a group, default `true`.
- `animateWidthTransform` / `animateHeightTransform: boolean?` — shrink the container along an axis as it hides (the collapse presets set these). Note: transform animations clip content while animating.
- `mapTransparency: ((alpha: number) -> number)?` — remap animation progress to transparency, default cubic-out.

Container passthrough: `size`, `automaticSize`, `position`, `anchorPoint`, `rotation`, `backgroundColor3`, `backgroundTransparency` (default `1`), `clipsDescendants`, `visible`, `zIndex`, `layoutOrder`, `tags`, `contentPosition`, `widthTransform` / `heightTransform` (explicit values beat the animated ones).

Group rendering: `groupTransparency` and `groupColor` apply to the content as a whole (the animated fade takes the max of `groupTransparency` and its own). `renderFloatingChildren` renders visuals like shadows outside the layout container; they fade with the content without being clipped.

`id` — same rules as everywhere in miu: optional, but pass one when the call is conditional or in a loop.
