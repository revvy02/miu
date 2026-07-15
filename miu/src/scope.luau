local RetainedScope = require(script.Parent.Parent.retained_scope)

export type MiuNode<T = {}> = RetainedScope.Node<T>

local scope = RetainedScope()
_G._MIU_ROOT = scope.root

return scope
