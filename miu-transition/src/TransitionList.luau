local Miu = require("../miu")
local DeltaTime = Miu.DeltaTime

local RemovingList = require("./RemovingList")
local Transition = require("./Transition")

--[[
	TransitionList - Animated list with enter/exit transitions per item

	Uses RemovingList to track items across frames (lifetime-driven: removed
	items animate out and unmount when their lifetime expires), then wraps
	each in a Transition. Supports opt-in trail/stagger animation.

	Props:
		items: { { id: string, ... } }    -- array of records
		keyer: ((item) -> string)?         -- custom key extractor (default: item.id)
		show: boolean?                     -- list-level visibility; items stay mounted
		                                   -- and the reveal/unravel animates (default:
		                                   -- shown while items is non-empty)
		animateTrailDelay: number?         -- delay between each item appearing
		animateTrailDuration: number?      -- total trail duration (overrides delay calc)
		+ all Transition props (preset, animateDirection, animateTransparency, etc.
		  — preset "collapseHeight" is the usual fit for rows)

	Trail is opt-in: only activates when animateTrailDelay or animateTrailDuration
	is set. The stagger is driven by ONE reversible alpha advancing at a constant
	rate (the Townies transition_list approach): showing reveals rows head-first,
	hiding unravels them tail-first, and toggling mid-flight resumes from the
	current alpha instead of restarting — seamless in both directions.

	Returns true while any row is still visible (useful for keeping overlays
	elevated until the exit animation finishes).

	Usage:
		TransitionList({
			items = items,
			show = open,
			animateHeightTransform = true,
			automaticSize = Enum.AutomaticSize.XY,
		}, function(key, item, removing)
			MyComponent(key, item)
		end)
]]

local DEFAULT_TRAIL_DELAY = 0.1

local function TransitionList(props, render)
	local entries, removing = RemovingList(props.items, props.keyer)
	local count = #entries

	-- Read before the per-row loop reuses props as each Transition's props table.
	local listShown = if props.show ~= nil then props.show else count > 0

	-- Without a trail all rows toggle together; with one, the trail alpha gates
	-- how many rows are revealed.
	local trailIndex = if listShown then count else 0
	local hasTrail = props.animateTrailDelay ~= nil or props.animateTrailDuration ~= nil

	if hasTrail then
		local node = Miu("trail")

		if count == 0 then
			-- Empty: the next population staggers from the start.
			node.trailAlpha = 1
		else
			-- The alpha runs 1 (none revealed) → 0 (all revealed) at a constant
			-- rate. Flipping `show` mid-flight just retargets it from the current
			-- value, so a close started mid-open unravels from exactly where the
			-- reveal got to, and vice versa.
			local totalDuration = props.animateTrailDuration or (count - 1) * (props.animateTrailDelay or DEFAULT_TRAIL_DELAY)
			local alpha = node.trailAlpha or 1
			local target = if listShown then 0 else 1

			if totalDuration > 0 then
				local step = DeltaTime() / totalDuration
				alpha = if alpha > target then math.max(target, alpha - step) else math.min(target, alpha + step)
			else
				alpha = target
			end

			node.trailAlpha = alpha
			trailIndex = math.ceil((1 - alpha) * count)
		end
	end

	local anyVisible = false

	-- Iterate all entries, pass props directly to Transition. Removed rows
	-- animate out via show=false and unmount when their lifetime expires.
	for i, record in entries do
		local isRemoving = removing[record.key] ~= nil

		props.id = record.key
		props.show = not isRemoving and i <= trailIndex
		props.layoutOrder = i

		local visible = Transition(props, function(rowVisible)
			if rowVisible then
				render(record.key, record.value, isRemoving)
			end
		end)

		anyVisible = anyVisible or visible
	end

	return anyVisible
end

return TransitionList
