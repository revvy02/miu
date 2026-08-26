--!strict
-- Flags early exits (return/break/continue) that jump over pending `.pop()` calls.
--
-- Analysis unit = one function body (nested functions are separate units). Within a
-- unit we track depth linearly: any `X.push(...)` member call is +1, any `X.pop(...)`
-- is -1. Component wrappers legitimately end at nonzero depth (View.push pushes for
-- its caller; View.pop pops bare), so imbalance alone is not an error. What is flagged:
--   - `return` at a depth greater than the unit's final straight-line depth
--     (it skips pops the normal path performs)
--   - `break`/`continue` at a depth greater than the enclosing loop body's entry depth
--     (it leaks pushes made in the current iteration)
-- Conditional/loop bodies are analyzed with inherited depth for exit detection but
-- contribute no net delta to their parent (conditional net pushes are their own smell).

local path = require("@std/path")
local syntax = require("@std/syntax")

type LintViolation = {
	lintname: string,
	location: syntax.Span,
	message: string,
	severity: "warning" | "error",
	sourcepath: path.Path?,
}

local name = "push_pop_balance"

type Exit = { node: syntax.CstStat, depth: number, kind: "return" | "break" | "continue", loopEntry: number }

local function isMemberCallNamed(expr: syntax.CstExpr, methodName: string): boolean
	if expr.tag ~= "call" then
		return false
	end
	local func = (expr :: syntax.CstExprCall).func
	return func.tag == "indexname" and (func :: syntax.CstExprIndexName).index.text == methodName
end

local function analyze(unitBody: syntax.CstStatBlock, report: (Exit, finalDepth: number) -> (), collectUnit: (syntax.CstStatBlock) -> ())
	local exits: { Exit } = {}

	local visitExpr: (syntax.CstExpr, delta: { number }) -> ()
	local analyzeBlock: (syntax.CstStatBlock, depth: number, loopEntry: number) -> number

	-- Walks an expression counting push/pop calls into `delta[1]`, collecting nested
	-- function bodies as separate units (they do not affect this unit's depth).
	function visitExpr(expr: syntax.CstExpr, delta: { number })
		local tag = expr.tag
		if tag == "call" then
			local call = expr :: syntax.CstExprCall
			if isMemberCallNamed(expr, "push") then
				delta[1] += 1
			elseif isMemberCallNamed(expr, "pop") then
				delta[1] -= 1
			end
			visitExpr(call.func, delta)
			for _, arg in call.arguments do
				visitExpr(arg, delta)
			end
		elseif tag == "indexname" then
			visitExpr((expr :: syntax.CstExprIndexName).expression, delta)
		elseif tag == "index" then
			local e = expr :: syntax.CstExprIndexExpr
			visitExpr(e.expression, delta)
			visitExpr(e.index, delta)
		elseif tag == "table" then
			for _, entry in (expr :: syntax.CstExprTable).entries do
				if entry.kind == "general" then
					visitExpr(entry.key, delta)
				end
				visitExpr(entry.value, delta)
			end
		elseif tag == "unary" then
			visitExpr((expr :: syntax.CstExprUnary).operand, delta)
		elseif tag == "binary" then
			local e = expr :: syntax.CstExprBinary
			visitExpr(e.lhsOperand, delta)
			visitExpr(e.rhsOperand, delta)
		elseif tag == "cast" then
			visitExpr((expr :: syntax.CstExprTypeAssertion).operand, delta)
		elseif tag == "interpolatedstring" then
			for _, e in (expr :: syntax.CstExprInterpString).expressions do
				visitExpr(e, delta)
			end
		elseif tag == "function" then
			collectUnit((expr :: syntax.CstExprFunction).body)
		end
	end

	-- Returns the block's net push/pop delta along the straight-line path.
	function analyzeBlock(block: syntax.CstStatBlock, depth: number, loopEntry: number): number
		local entry = depth
		for _, stat in block.statements do
			local tag = stat.tag
			local delta = { 0 }
			if tag == "expression" then
				visitExpr((stat :: syntax.CstStatExpr).expression, delta)
			elseif tag == "local" then
				for _, value in (stat :: syntax.CstStatLocal).values do
					visitExpr(value, delta)
				end
			elseif tag == "assign" then
				for _, value in (stat :: syntax.CstStatAssign).values do
					visitExpr(value, delta)
				end
			elseif tag == "return" then
				for _, e in (stat :: syntax.CstStatReturn).expressions do
					visitExpr(e, delta)
				end
				depth += delta[1]
				table.insert(exits, { node = stat, depth = depth, kind = "return" :: "return", loopEntry = loopEntry })
				continue
			elseif tag == "break" then
				table.insert(exits, { node = stat, depth = depth, kind = "break" :: "break", loopEntry = loopEntry })
				continue
			elseif tag == "continue" then
				table.insert(exits, { node = stat, depth = depth, kind = "continue" :: "continue", loopEntry = loopEntry })
				continue
			elseif tag == "do" then
				depth += analyzeBlock((stat :: syntax.CstStatDo).body, depth, loopEntry)
				continue
			elseif tag == "conditional" then
				local cond = stat :: syntax.CstStatIf
				analyzeBlock(cond.thenBlock, depth, loopEntry)
				for _, elseif_ in cond.elseifs do
					analyzeBlock(elseif_.thenBlock, depth, loopEntry)
				end
				if cond.elseBlock then
					analyzeBlock(cond.elseBlock, depth, loopEntry)
				end
				continue
			elseif tag == "while" then
				analyzeBlock((stat :: syntax.CstStatWhile).body, depth, depth)
				continue
			elseif tag == "repeat" then
				analyzeBlock((stat :: syntax.CstStatRepeat).body, depth, depth)
				continue
			elseif tag == "for" then
				analyzeBlock((stat :: syntax.CstStatFor).body, depth, depth)
				continue
			elseif tag == "forin" then
				for _, value in (stat :: syntax.CstStatForIn).values do
					visitExpr(value, delta)
				end
				depth += delta[1]
				analyzeBlock((stat :: syntax.CstStatForIn).body, depth, depth)
				continue
			elseif tag == "function" then
				collectUnit((stat :: syntax.CstStatFunction).func.body)
				continue
			elseif tag == "localfunction" then
				collectUnit((stat :: syntax.CstStatLocalFunction).func.body)
				continue
			end
			depth += delta[1]
		end
		return depth - entry
	end

	local finalDepth = analyzeBlock(unitBody, 0, 0)
	for _, exit in exits do
		report(exit, finalDepth)
	end
end

local function lint(cst: syntax.CstStatBlock, sourcepath: path.Path?): { LintViolation }
	local violations: { LintViolation } = {}
	local units: { syntax.CstStatBlock } = { cst }
	local collectUnit = function(body: syntax.CstStatBlock)
		table.insert(units, body)
	end

	local i = 1
	while i <= #units do
		analyze(units[i], function(exit, finalDepth)
			local leaked = if exit.kind == "return" then exit.depth - math.max(finalDepth, 0) else exit.depth - exit.loopEntry
			if leaked > 0 then
				table.insert(violations, {
					lintname = name,
					location = exit.node.location,
					message = `this {exit.kind} skips {leaked} pending pop() call{if leaked == 1 then "" else "s"}; pop before exiting, or use the bracket form which pops for you`,
					severity = "warning" :: "warning",
					sourcepath = sourcepath,
				})
			end
		end, collectUnit)
		i += 1
	end

	return violations
end

local rule = {
	name = name,
	lint = lint,
}

return table.freeze(rule)
