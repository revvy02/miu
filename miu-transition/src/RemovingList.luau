local Miu = require("../miu")

--[[
	RemovingList - Array persistence with keying and stable ordering

	The ordered counterpart to RemovingDictionary, same design: persistent
	state on the node (no per-frame table allocations beyond first-seen
	records), lifetime-driven removal with automatic recovery when a key
	reappears before its lifetime expires.

	Records persist per key and are refreshed in place each frame:
		{ index, key, value, timestamp }
		- index: position in the source array (remembered while removing)
		- key: from keyer(item), or item.id
		- value: the source item (last seen)
		- timestamp: first-seen time, preserved across frames and recovery

	Entries sort by (index, timestamp): items follow input order, removed
	items hold their remembered position, ties order by first appearance.

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

local function byIndexThenTimestamp(a, b)
	if a.index ~= b.index then
		return a.index < b.index
	end
	return a.timestamp < b.timestamp
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
			records[key] = { index = i, key = key, value = item, timestamp = t0, stamp = frame }
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
	table.sort(entries, byIndexThenTimestamp)

	return entries, removing
end

return RemovingList
