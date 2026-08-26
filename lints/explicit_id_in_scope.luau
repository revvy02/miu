--!strict
-- Flags miu node-creating calls that rely on auto-cursor ids inside loops or branches.
--
-- Auto-cursor ids are positional: when a call runs conditionally or a varying number
-- of times, the cursor shifts between frames and retained state migrates to the wrong
-- node (the immediate-mode analog of React's rules of hooks). Inside any loop or
-- conditional, creation calls must carry an explicit id.
--
-- Creation calls recognized:
--   - `X.push(classString, props?)`  (Element-style: first arg is a string literal)
--   - `X.push(props?)`               (component-style: first arg is a table or absent)
--   - `Miu(...)` / `Element(...)`    (direct scope/bracket calls by conventional name)
-- The id is satisfied by a string/number literal first argument (`Miu("id", fn)`) or an
-- `id` field in a props table literal. Props passed as variables are skipped (unknown).
-- Non-creation callbacks are walked with the surrounding loop/branch context (they run
-- in the same frame at the same scope level); a creation call's bracket callback resets
-- it, since children's cursors are relative to the created node.

local path = require("@std/path")
local syntax = require("@std/syntax")

type LintViolation = {
	lintname: string,
	location: syntax.Span,
	message: string,
	severity: "warning" | "error",
	sourcepath: path.Path?,
}

local name = "explicit_id_in_scope"

local DIRECT_CALL_NAMES = { Miu = true, Element = true }

local function isLiteralId(expr: syntax.CstExpr): boolean
	return expr.tag == "string" or expr.tag == "number" or expr.tag == "interpolatedstring"
end

local function tableHasIdField(expr: syntax.CstExpr): boolean
	for _, entry in (expr :: syntax.CstExprTable).entries do
		if entry.kind == "record" and entry.key.text == "id" then
			return true
		end
	end
	return false
end

local function isCreationCall(call: syntax.CstExprCall): (boolean, boolean)
	local func = call.func
	local isPush = func.tag == "indexname" and (func :: syntax.CstExprIndexName).index.text == "push"
	local isDirect = false
	if func.tag == "global" then
		isDirect = DIRECT_CALL_NAMES[(func :: syntax.CstExprGlobal).name.text] == true
	elseif func.tag == "local" then
		isDirect = DIRECT_CALL_NAMES[(func :: syntax.CstExprLocal)["local"].name.text] == true
	end
	return isPush or isDirect, isPush
end

-- Returns a violation message if this call creates a node without an explicit id,
-- nil if it carries one or we can't tell.
local function checkCreationCall(call: syntax.CstExprCall): string?
	local args = call.arguments

	local isCreation, isPush = isCreationCall(call)
	local isDirect = isCreation and not isPush
	if not isCreation then
		return nil
	end

	local first = args[1]

	-- Miu("id", fn) / Element("Frame", props, fn): string first arg
	if first and isLiteralId(first) then
		if isDirect and not isPush and args[2] and args[2].tag == "function" then
			-- Miu("id", fn): the string IS the id
			return nil
		end
		-- Element-style: id lives in the props table
		local props = args[2]
		if props == nil then
			return `this call relies on the auto-cursor id; pass props with an explicit id`
		end
		if props.tag == "table" then
			return if tableHasIdField(props) then nil else `props are missing an explicit id`
		end
		return nil -- props passed as a variable: can't tell
	end

	-- Miu(fn): scope with no id at all
	if isDirect and first and first.tag == "function" then
		return `this scope relies on the auto-cursor id; pass an id as the first argument`
	end

	-- component-style push(props?) / push()
	if isPush then
		if first == nil then
			return `this call relies on the auto-cursor id; pass props with an explicit id`
		end
		if first.tag == "table" then
			return if tableHasIdField(first) then nil else `props are missing an explicit id`
		end
	end

	return nil -- unknown shape: stay quiet
end

local function lint(cst: syntax.CstStatBlock, sourcepath: path.Path?): { LintViolation }
	local violations: { LintViolation } = {}

	local visitExpr: (syntax.CstExpr, scoped: number) -> ()
	local visitBlock: (syntax.CstStatBlock, scoped: number) -> ()

	local function visitCall(call: syntax.CstExprCall, scoped: number)
		if scoped > 0 then
			local problem = checkCreationCall(call)
			if problem then
				table.insert(violations, {
					lintname = name,
					location = call.location,
					message = `{problem} (auto-cursor ids shift between frames inside loops and branches)`,
					severity = "warning" :: "warning",
					sourcepath = sourcepath,
				})
			end
		end
	end

	function visitExpr(expr: syntax.CstExpr, scoped: number)
		local tag = expr.tag
		if tag == "call" then
			local call = expr :: syntax.CstExprCall
			visitCall(call, scoped)
			visitExpr(call.func, scoped)
			-- A creation call's bracket callback opens a fresh node scope: children's
			-- cursor is relative to the created node, so the loop/branch hazard does
			-- not propagate into it. Only the creating call itself needs the id.
			local resetsScope = isCreationCall(call)
			for _, arg in call.arguments do
				visitExpr(arg, if resetsScope and arg.tag == "function" then 0 else scoped)
			end
		elseif tag == "indexname" then
			visitExpr((expr :: syntax.CstExprIndexName).expression, scoped)
		elseif tag == "index" then
			local e = expr :: syntax.CstExprIndexExpr
			visitExpr(e.expression, scoped)
			visitExpr(e.index, scoped)
		elseif tag == "table" then
			for _, entry in (expr :: syntax.CstExprTable).entries do
				if entry.kind == "general" then
					visitExpr(entry.key, scoped)
				end
				visitExpr(entry.value, scoped)
			end
		elseif tag == "unary" then
			visitExpr((expr :: syntax.CstExprUnary).operand, scoped)
		elseif tag == "binary" then
			local e = expr :: syntax.CstExprBinary
			visitExpr(e.lhsOperand, scoped)
			visitExpr(e.rhsOperand, scoped)
		elseif tag == "cast" then
			visitExpr((expr :: syntax.CstExprTypeAssertion).operand, scoped)
		elseif tag == "interpolatedstring" then
			for _, e in (expr :: syntax.CstExprInterpString).expressions do
				visitExpr(e, scoped)
			end
		elseif tag == "function" then
			-- bracket-form callbacks run in the surrounding frame: keep the context
			visitBlock((expr :: syntax.CstExprFunction).body, scoped)
		end
	end

	local function visitStatExprs(stat: syntax.CstStat, scoped: number)
		local tag = stat.tag
		if tag == "expression" then
			visitExpr((stat :: syntax.CstStatExpr).expression, scoped)
		elseif tag == "local" then
			for _, value in (stat :: syntax.CstStatLocal).values do
				visitExpr(value, scoped)
			end
		elseif tag == "assign" then
			for _, value in (stat :: syntax.CstStatAssign).values do
				visitExpr(value, scoped)
			end
		elseif tag == "return" then
			for _, e in (stat :: syntax.CstStatReturn).expressions do
				visitExpr(e, scoped)
			end
		end
	end

	function visitBlock(block: syntax.CstStatBlock, scoped: number)
		for _, stat in block.statements do
			local tag = stat.tag
			if tag == "conditional" then
				local cond = stat :: syntax.CstStatIf
				visitExpr(cond.condition, scoped)
				visitBlock(cond.thenBlock, scoped + 1)
				for _, elseif_ in cond.elseifs do
					visitExpr(elseif_.condition, scoped)
					visitBlock(elseif_.thenBlock, scoped + 1)
				end
				if cond.elseBlock then
					visitBlock(cond.elseBlock, scoped + 1)
				end
			elseif tag == "while" then
				local loop = stat :: syntax.CstStatWhile
				visitExpr(loop.condition, scoped)
				visitBlock(loop.body, scoped + 1)
			elseif tag == "repeat" then
				local loop = stat :: syntax.CstStatRepeat
				visitBlock(loop.body, scoped + 1)
				visitExpr(loop.condition, scoped)
			elseif tag == "for" then
				local loop = stat :: syntax.CstStatFor
				visitExpr(loop.from, scoped)
				visitExpr(loop.to, scoped)
				if loop.step then
					visitExpr(loop.step, scoped)
				end
				visitBlock(loop.body, scoped + 1)
			elseif tag == "forin" then
				local loop = stat :: syntax.CstStatForIn
				for _, value in loop.values do
					visitExpr(value, scoped)
				end
				visitBlock(loop.body, scoped + 1)
			elseif tag == "do" then
				visitBlock((stat :: syntax.CstStatDo).body, scoped)
			elseif tag == "function" then
				visitBlock((stat :: syntax.CstStatFunction).func.body, 0)
			elseif tag == "localfunction" then
				visitBlock((stat :: syntax.CstStatLocalFunction).func.body, 0)
			else
				visitStatExprs(stat, scoped)
			end
		end
	end

	visitBlock(cst, 0)
	return violations
end

local rule = {
	name = name,
	lint = lint,
}

return table.freeze(rule)
