local function unmounting(node)
	if node.connections then
		for _, conn in node.connections do
			conn:Disconnect()
		end
	end
	if node.instance and not node.isPortal then
		node.instance.Parent = nil
	end
	node.parent.children[node.id] = nil
	node.mounted = false
end

return unmounting
