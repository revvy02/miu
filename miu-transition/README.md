# miu-transition

`Smooth` lives in miu now: `require("@pkg/miu").Smooth`.

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
