local Instance = require("../miu").Instance

-- True if `new` differs from `old` (added/changed/removed keys), so we only
-- write to the instance when something actually changed.
local function changed(old, new)
	if not old then
		return true
	end
	for k, v in new do
		if old[k] ~= v then
			return true
		end
	end
	for k in old do
		if new[k] == nil then
			return true
		end
	end
	return false
end

-- StyleRule(selector, properties, transitions?, priority?)
--   properties:  { [PropertyName]: value }
--   transitions: { [PropertyName]: TweenInfo } — animates that property when its
--                value changes (Roblox StyleRule:SetPropertyTransitions).
--   priority:    rule priority (default 0).
local function StyleRule(selector, properties, transitions, priority)
	return Instance("StyleRule", { Name = selector, Selector = selector, Priority = priority or 0 }, function(node)
		if properties and changed(node.ruleProperties, properties) then
			node.instance:SetProperties(properties)
			node.ruleProperties = properties
		end

		if transitions and changed(node.ruleTransitions, transitions) then
			node.instance:SetPropertyTransitions(transitions)
			node.ruleTransitions = transitions
		end
	end)
end

return StyleRule
