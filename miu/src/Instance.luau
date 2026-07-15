local miu = require("./scope")
local unmounting = require("./unmounting")

type MiuNode<T = {}> = miu.MiuNode<T>

local MIU_PUSH = miu.push

local function on_remove(_parent, _id, child)
	unmounting(child)
end

local function reactor_pop()
	miu.prune(miu.peek(), on_remove)
	miu.pop()
end

local function attributes(instance, new, old)
	debug.profilebegin("hydrate_attributes")
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
	debug.profileend()
end

local function tags(instance, new, old)
	debug.profilebegin("hydrate_tags")
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
	debug.profileend()
end

-- Handlers are inline closures, so their identity changes every frame. Diffing them would
-- reconnect every event every frame. Instead we connect ONCE to a trampoline that dispatches
-- to the current handler, and per frame just swap the stored handler ref (a field write). The
-- connection is created when an event name first appears and torn down only when it's dropped.
local function events(node, instance, new, old)
	debug.profilebegin("hydrate_events")
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
	debug.profileend()
end

local function update(node, newProps)
	debug.profilebegin("update")
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
	debug.profileend()
end

local function push<T>(class, props): MiuNode<T>
	props = props or {}
	local node = MIU_PUSH(props.id)

	if not node.mounted then
		node.instance = Instance.new(class)
		node.instance.Parent = node.parent.instance

		node.events = {}
		node.connections = {}

		node.props = {}
		node.mounted = true
	elseif node.instance.Parent ~= node.parent.instance then
		node.instance.Parent = node.parent.instance
	end

	update(node, props)
	node.props = props

	return node :: any
end

local function pop()
	reactor_pop()
end

local function scope<T>(class, props, fn): MiuNode<T>
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
	__call = function(_, class, props, fn)
		return scope(class, props, fn)
	end,
})
