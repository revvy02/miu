local Miu = require("../miu")

--[[
	RemovingList - Array persistence with keying and stable ordering

	The ordered counterpart to RemovingDictionary, same design: persistent
	state on the node (no per-frame table allocations beyond first-seen
	records), lifetime-driven removal with automatic recovery when a key
	reappears before its lifetime expires.

	Records persist per key and are refreshed in place each frame:
		{ index, key, value, timestamp, seq }
		- index: position in the source array (remembered while removing)
		- key: from keyer(item), or item.id
		- value: the source item (last seen)
		- timestamp: first-seen time, preserved across frames and recovery
		- seq: first-seen order, strictly increasing

	Entries sort by (index, seq): items follow input order, removed items
	hold their remembered position, and ties order by first appearance.
	The tiebreak must be `seq`, not `timestamp`: same-frame records share
	one clock reading, and a removed row ties on index with the row that
	shifted up into its slot — with equal timestamps the sort is arbitrary
	and the exiting row can jump below its successor mid-animation.

	Returns (entries, removing):
		entries: { record } — sorted, rebuilt in place each frame
		removing: { [key]: number } — removal start time per removing key

	Both returned tables are the live internal ones: iterate, don't retain
	or mutate.

	Usage:
		local entries, removing = RemovingList(items)
		for i, record in entries do
			-- record.key, record.value, removing[record.key]
		end
]]

local function byIndexThenSeq(a, b)
	if a.index ~= b.index then
		return a.index < b.index
	end
	return a.seq < b.seq
end

local function RemovingList(items, keyer, lifetime)
	lifetime = lifetime or 1

	local state = Miu("RemovingList")
	local records, removing, entries = state.records, state.removing, state.entries

	if not records then
		records = {}
		removing = {}
		entries = {}
		state.records = records
		state.removing = removing
		state.entries = entries
	end

	local t0 = os.clock()
	local frame = (state.frame or 0) + 1
	state.frame = frame

	-- Refresh records in place; allocate only for first-seen keys
	for i, item in items do
		local key = if keyer then keyer(item) else item.id
		local record = records[key]
		if record then
			record.index = i
			record.value = item
			record.stamp = frame
		else
			local seq = (state.seq or 0) + 1
			state.seq = seq
			records[key] = { index = i, key = key, value = item, timestamp = t0, seq = seq, stamp = frame }
		end
		if removing[key] then -- cancel removal
			removing[key] = nil
		end
	end

	-- Records not stamped this frame have left the input (arrays have no keyed
	-- lookup, so the stamp stands in for RemovingDictionary's `dict[k] == nil`)
	for key, record in records do
		if record.stamp ~= frame and not removing[key] then
			removing[key] = t0
		end
	end

	-- Complete removals past their lifetime
	for key, t1 in removing do
		if t0 - t1 >= lifetime then
			records[key] = nil
			removing[key] = nil
		end
	end

	-- Rebuild the ordered view in place
	table.clear(entries)
	for _, record in records do
		table.insert(entries, record)
	end
	table.sort(entries, byIndexThenSeq)

	return entries, removing
end

return RemovingList
