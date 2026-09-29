local classes = require("./classes")
local miu = require("./scope")
local unmounting = require("./unmounting")

type MiuNode<T = {}> = miu.MiuNode<T>
type CreatableInstances = classes.CreatableInstances

-- Derives the props type for a class-name singleton: every writable instance
-- property (optional), plus the miu extras (id/attributes/tags/events). Signals
-- are routed into `events` typed with their real handler signatures. The
-- [string]: never indexers reject typos and wrong-class props.
--
-- KNOWN LIMITATION (luau-lang/luau#2608): the solver checks a table-literal
-- argument against MiuProps<C> before reducing it, so literal props at push
-- call sites error with the unreduced type until that fix lands. Props passed
-- through an annotated variable, and all scalar checking, work today.
-- selene: allow(undefined_variable) -- type aliases read as values inside type function bodies
type function MiuProps(selector: type)
	local cls = CreatableInstances:readproperty(selector)
	assert(cls, "miu: not a creatable Instance class: " .. tostring(selector))

	local props = types.newtable()
	local events = types.newtable()
	local current: any = cls
	while current do
		for name, prop in current:properties() do
			local write = prop.write
			if not write or props:readproperty(name) ~= nil or events:readproperty(name) ~= nil then
				continue
			end
			if write:is("function") then
				continue
			end
			if write:is("table") then
				-- RBXScriptSignal shape: { Connect: (self, handler) -> ... }
				local connect = write:readproperty(types.singleton("Connect"))
				if connect and connect:is("function") then
					local params = connect:parameters().head
					if params and params[2] then
						events:setproperty(name, types.optional(params[2]))
						continue
					end
				end
			end
			props:setproperty(name, types.optional(write))
		end
		current = current:readparent()
	end

	events:setindexer(types.string, types.never)
	props:setproperty(types.singleton("id"), types.optional(types.unionof(types.string, types.number)))
	props:setproperty(
		types.singleton("attributes"),
		types.optional(types.newtable(nil, { index = types.string, readresult = types.any, writeresult = types.any }))
	)
	props:setproperty(
		types.singleton("tags"),
		types.optional(types.newtable(nil, { index = types.number, readresult = types.string, writeresult = types.string }))
	)
	props:setproperty(types.singleton("events"), types.optional(events))
	props:setindexer(types.string, types.never)
	return props
end

local MIU_PUSH = miu.push

-- Set _G._MIU_PROFILER_LABELS = true before miu is first required to wrap each element's prop
-- update in microprofiler labels (update, hydrate_*). Off by default: they cost a few percent of
-- every walk. Read once here, so setting it later has no effect.
local PROFILER_LABELS = _G._MIU_PROFILER_LABELS == true

local function on_remove(_parent, _id, child)
	unmounting(child)
end

local function reactor_pop()
	miu.prune(miu.peek(), on_remove)
	miu.pop()
end

local function attributes(instance, new, old)
	if PROFILER_LABELS then
		debug.profilebegin("hydrate_attributes")
	end
	if old then
		for attr, val in new do
			if old[attr] ~= val then
				instance:SetAttribute(attr, val)
			end
		end

		for attr in old do
			if new[attr] == nil then
				instance:SetAttribute(attr, nil)
			end
		end
	else
		for attr, val in new do
			instance:SetAttribute(attr, val)
		end
	end
	if PROFILER_LABELS then
		debug.profileend()
	end
end

-- Tags usually come from an inline table literal, so they arrive as a fresh table every walk
-- holding the same entries. Compared index by index both ways, not by length: a literal with a
-- conditional entry can have nil holes, which make # unreliable.
local function sameTags(a, b)
	for i, tag in a do
		if b[i] ~= tag then
			return false
		end
	end
	for i, tag in b do
		if a[i] ~= tag then
			return false
		end
	end
	return true
end

local function tags(instance, new, old)
	if old and sameTags(new, old) then
		return
	end
	if PROFILER_LABELS then
		debug.profilebegin("hydrate_tags")
	end
	if old then
		for _, tag in new do
			if not table.find(old, tag) then
				instance:AddTag(tag)
			end
		end
		for _, tag in old do
			if not table.find(new, tag) then
				instance:RemoveTag(tag)
			end
		end
	else
		for _, tag in new do
			instance:AddTag(tag)
		end
	end
	if PROFILER_LABELS then
		debug.profileend()
	end
end

-- Handlers are inline closures, so their identity changes every frame. Diffing them would
-- reconnect every event every frame. Instead we connect ONCE to a trampoline that dispatches
-- to the current handler, and per frame just swap the stored handler ref (a field write). The
-- connection is created when an event name first appears and torn down only when it's dropped.
local function events(node, instance, new, old)
	if PROFILER_LABELS then
		debug.profilebegin("hydrate_events")
	end
	local handlers = node.events
	local connections = node.connections

	for name, handler in new do
		if connections[name] == nil then
			connections[name] = instance[name]:Connect(function(...)
				local current = handlers[name]
				if current then
					return current(...)
				end
				return nil
			end)
		end
		handlers[name] = handler
	end

	if old then
		for name in old do
			if new[name] == nil then
				connections[name]:Disconnect()
				connections[name] = nil
				handlers[name] = nil
			end
		end
	end
	if PROFILER_LABELS then
		debug.profileend()
	end
end

local function update(node, newProps)
	if PROFILER_LABELS then
		debug.profilebegin("update")
	end
	local instance = node.instance
	local oldProps = node.props

	for k, v in newProps do
		if k == "id" then
			continue
		elseif k == "attributes" then
			attributes(instance, v, oldProps.attributes)
		elseif k == "tags" then
			tags(instance, v, oldProps.tags)
		elseif k == "events" then
			events(node, instance, v, oldProps.events)
		elseif oldProps[k] ~= v then
			instance[k] = v
		end
	end
	if PROFILER_LABELS then
		debug.profileend()
	end
end

local function push<C, T>(class: C & (string | ""), propsIn: MiuProps<C>?): MiuNode<T>
	local props: any = propsIn or {}
	local node = MIU_PUSH(props.id)

	if not node.mounted then
		node.instance = Instance.new(class :: any)
		-- Name the instance after its id so the Explorer reads as the tree you wrote. Auto-cursor
		-- ids are numbers, which still beats a pile of identically named siblings. Creation only —
		-- an id never changes, and an explicit Name prop wins (update() writes it right below).
		if props.Name == nil then
			node.instance.Name = tostring(node.id)
		end
		node.instance.Parent = node.parent.instance
		node.parentInstance = node.parent.instance

		node.events = {}
		node.connections = {}

		node.props = {}
		node.mounted = true
	elseif node.parentInstance ~= node.parent.instance then
		-- Compared against the parent miu assigned last, not Instance.Parent: reading a property
		-- is an engine call, per element per walk. Only miu parents these instances, so the two
		-- agree; one reparented from outside miu is no longer moved back.
		node.instance.Parent = node.parent.instance
		node.parentInstance = node.parent.instance
	end

	update(node, props)
	node.props = props

	return node :: any
end

local function pop()
	reactor_pop()
end

local function scope<C, T>(class: C & (string | ""), props: MiuProps<C>?, fn: ((MiuNode<T>) -> ())?): MiuNode<T>
	local node = push(class, props)
	if fn then
		fn(node)
	end
	reactor_pop()
	return node :: any
end

return setmetatable({
	push = push,
	pop = pop,
}, {
	__call = function<C, T>(_, class: C & (string | ""), props: MiuProps<C>?, fn: ((MiuNode<T>) -> ())?): MiuNode<T>
		return scope(class, props, fn)
	end,
})
