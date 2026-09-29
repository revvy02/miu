-- The list the Transition fixtures render: collapseHeight Transitions in one UIListLayout, each
-- around a label. `settled` rows always show; `flipping` rows flip `show` every walk and set their
-- height to half or full directly, so every walk changes their size by the same whole number of
-- pixels. (Left to ease by real time, their size change would depend on how long each walk took,
-- and so would the fixture's cost.) The label renders even while hidden, so the instance count
-- stays fixed.
return function(pkgs)
	local Element = pkgs.miu.Element
	local Transition = pkgs.transition.Transition

	local function row(id, show, heightTransform)
		Transition({
			id = id,
			show = show,
			preset = "collapseHeight",
			heightTransform = heightTransform,
			size = UDim2.fromScale(1, 0),
			automaticSize = Enum.AutomaticSize.Y,
		}, function()
			Element("TextLabel", { Size = UDim2.new(1, 0, 0, 16), Text = id })
		end)
	end

	return function(walk: number, settled: number, flipping: number)
		Element("Frame", { id = "list", Size = UDim2.fromScale(1, 1) }, function()
			Element("UIListLayout", {})
			for n = 1, math.max(settled, flipping) do
				if n <= settled then
					row("settled" .. n, true)
				end
				if n <= flipping then
					local shown = walk % 2 == 0
					row("flipping" .. n, shown, if shown then 1 else 0.5)
				end
			end
		end)
	end
end
