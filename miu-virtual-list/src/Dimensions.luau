--[[ Dimensions — composable layout specs for VirtualList

	Port of ultimate-list's Dimensions + DimensionsMethods.
	Three base types:
		consistentSize(n)     — all items same height/width
		consistentUDim2(u)    — grid cells
		getter(fn)            — arbitrary per-item dimensions
	Plus a composable wrapper:
		withSpacing(inner, n) — adds gaps between items
]]

local Miu = require(script.Parent.Parent.miu)

export type UDimRect = {
	size: UDim2,
	position: UDim2,
}

export type Dimensions =
	{ type: "consistentSize", size: number }
	| { type: "consistentUDim2", udim2: UDim2 }
	| { type: "getter", callback: (value: any, index: number) -> UDimRect }
	| { type: "spaced", spacing: number, inner: Dimensions }

-- Constructors ----------------------------------------------------------------

local Dimensions = {}

function Dimensions.consistentSize(size: number): Dimensions
	return {
		type = "consistentSize",
		size = size,
	}
end

function Dimensions.cachedFirstAbsoluteSize(fallback: number): Dimensions
	local state = Miu()
	if not state.dimensions then
		state.dimensions = {
			type = "consistentSize",
			size = fallback,
			_measureFirstItem = true,
		}
	end
	return state.dimensions
end

function Dimensions.consistentUDim2(udim2: UDim2): Dimensions
	return {
		type = "consistentUDim2",
		udim2 = udim2,
	}
end

function Dimensions.getter(callback: (value: any, index: number) -> UDimRect): Dimensions
	return {
		type = "getter",
		callback = callback,
	}
end

function Dimensions.withSpacing(inner: Dimensions, spacing: number): Dimensions
	assert(
		inner.type ~= "getter",
		"withSpacing does not support getter. Instead, include your padding as part of your returned position."
	)

	-- Flatten nested spaced
	if inner.type == "spaced" then
		return Dimensions.withSpacing(inner.inner, spacing)
	end

	return {
		type = "spaced",
		spacing = spacing,
		inner = inner,
	}
end

-- Methods ---------------------------------------------------------------------

-- If direction == "x": the number of rows per column.
-- If direction == "y": the number of columns per row.
function Dimensions.getAmountPerNonDominant(udim2: UDim2, windowSize: Vector2, direction: string): number
	if direction == "x" then
		return math.max(1, windowSize.Y // (udim2.Y.Offset + udim2.Y.Scale * windowSize.Y))
	else
		return math.max(1, windowSize.X // (udim2.X.Offset + udim2.X.Scale * windowSize.X))
	end
end

local function getDominantAxis(vector: Vector2, direction: string): number
	if direction == "x" then
		return vector.X
	else
		return vector.Y
	end
end

local function getUDimSizeForConsistentSize(size: number, direction: string): UDim2
	if direction == "x" then
		return UDim2.new(0, size, 1, 0)
	else
		return UDim2.new(1, 0, 0, size)
	end
end

local function getPositionForConsistentSize(size: number, index: number, direction: string): UDim2
	if direction == "x" then
		return UDim2.fromOffset(size * (index - 1), 0)
	else
		return UDim2.fromOffset(0, size * (index - 1))
	end
end

local function getPositionForConsistentUDim2(
	udim2: UDim2,
	index: number,
	windowSize: Vector2,
	direction: string
): UDim2
	local amountPerNonDominant = Dimensions.getAmountPerNonDominant(udim2, windowSize, direction)

	if direction == "x" then
		return UDim2.new(
			0,
			(math.ceil(index / amountPerNonDominant) - 1) * udim2.X.Offset,
			udim2.Y.Scale * ((index - 1) % amountPerNonDominant),
			udim2.Y.Offset * ((index - 1) % amountPerNonDominant)
		)
	else
		return UDim2.new(
			udim2.X.Scale * ((index - 1) % amountPerNonDominant),
			udim2.X.Offset * ((index - 1) % amountPerNonDominant),
			0,
			(math.ceil(index / amountPerNonDominant) - 1) * udim2.Y.Offset
		)
	end
end

function Dimensions.getUDimRect(
	dimensions: Dimensions,
	item: any,
	index: number,
	windowSize: Vector2,
	direction: string
): UDimRect
	if dimensions.type == "consistentSize" then
		return {
			size = getUDimSizeForConsistentSize(dimensions.size, direction),
			position = getPositionForConsistentSize(dimensions.size, index, direction),
		}
	elseif dimensions.type == "consistentUDim2" then
		return {
			size = dimensions.udim2,
			position = getPositionForConsistentUDim2(dimensions.udim2, index, windowSize, direction),
		}
	elseif dimensions.type == "getter" then
		return dimensions.callback(item, index)
	elseif dimensions.type == "spaced" then
		if dimensions.inner.type == "consistentSize" then
			return {
				size = getUDimSizeForConsistentSize(dimensions.inner.size, direction),
				position = getPositionForConsistentSize(dimensions.inner.size + dimensions.spacing, index, direction),
			}
		elseif dimensions.inner.type == "consistentUDim2" then
			return {
				size = dimensions.inner.udim2,
				position = getPositionForConsistentUDim2(
					dimensions.inner.udim2
						+ UDim2.fromOffset(
							if direction == "x" then dimensions.spacing else 0,
							if direction == "y" then dimensions.spacing else 0
						),
					index,
					windowSize,
					direction
				),
			}
		else
			error("Unsupported spaced dimensions")
		end
	else
		error("Unknown dimension type: " .. tostring(dimensions.type))
	end
end

function Dimensions.getCanvasSize(dimensions: Dimensions, data: { any }, windowSize: Vector2, direction: string): UDim2
	if #data == 0 then
		return UDim2.new()
	end

	local udimRect = Dimensions.getUDimRect(dimensions, data[#data], #data, windowSize, direction)
	if direction == "x" then
		return UDim2.fromOffset(udimRect.position.X.Offset + udimRect.size.X.Offset, 0)
	else
		return UDim2.fromOffset(0, udimRect.position.Y.Offset + udimRect.size.Y.Offset)
	end
end

-- Visible range calculation ---------------------------------------------------

local function getVisibleRangeConsistentSize(scrollAxis: number, windowAxis: number, size: number, dataLength: number): (number, number)
	local head = 1 + scrollAxis // size
	local tail = 1 + (scrollAxis + windowAxis) // size

	return math.max(1, head), math.min(dataLength, tail)
end

local function getVisibleRangeGrid(
	scrollAxis: number,
	windowAxis: number,
	udim2: UDim2,
	windowSize: Vector2,
	direction: string,
	dataLength: number
): (number, number)
	local amountPerNonDominant = Dimensions.getAmountPerNonDominant(udim2, windowSize, direction)

	local dominantSize = if direction == "x" then udim2.X.Offset else udim2.Y.Offset

	local head = 1 + (scrollAxis // dominantSize) * amountPerNonDominant
	local tail = (1 + (scrollAxis + windowAxis) // dominantSize) * amountPerNonDominant

	return math.max(1, head), math.min(dataLength, tail)
end

-- Binary search + linear expansion for getter dimensions.
-- Port of binarySearchIndexRangeInView, simplified from cursor-based to array-indexed.
local function getVisibleRangeGetter(
	data: { any },
	getUDimRect: (value: any, index: number) -> UDimRect,
	scrollAxis: number,
	windowAxis: number,
	direction: string
): (number, number)
	local function compareInView(udimRect: UDimRect): string
		local position = if direction == "x" then udimRect.position.X.Offset else udimRect.position.Y.Offset
		local size = if direction == "x" then udimRect.size.X.Offset else udimRect.size.Y.Offset

		if position + size < scrollAxis then
			return "before"
		elseif position > scrollAxis + windowAxis then
			return "after"
		else
			return "inside"
		end
	end

	local low = 1
	local high = #data

	while low <= high do
		local mid = (low + high) // 2
		local comparison = compareInView(getUDimRect(data[mid], mid))

		if comparison == "after" then
			high = mid - 1
		elseif comparison == "before" then
			low = mid + 1
		elseif comparison == "inside" then
			-- Found an item inside the view, expand outward
			local min = mid
			while min > 1 do
				if compareInView(getUDimRect(data[min - 1], min - 1)) ~= "inside" then
					break
				end
				min -= 1
			end

			local max = mid
			while max < #data do
				if compareInView(getUDimRect(data[max + 1], max + 1)) ~= "inside" then
					break
				end
				max += 1
			end

			return min, max
		end
	end

	return 0, 0
end

-- Dispatch to the correct range algorithm based on dimension type.
function Dimensions.getVisibleRange(
	dimensions: Dimensions,
	data: { any },
	scrollAxis: number,
	windowAxis: number,
	windowSize: Vector2,
	direction: string
): (number, number)
	if dimensions.type == "consistentSize" then
		return getVisibleRangeConsistentSize(scrollAxis, windowAxis, dimensions.size, #data)
	elseif dimensions.type == "consistentUDim2" then
		return getVisibleRangeGrid(scrollAxis, windowAxis, dimensions.udim2, windowSize, direction, #data)
	elseif dimensions.type == "getter" then
		return getVisibleRangeGetter(data, dimensions.callback, scrollAxis, windowAxis, direction)
	elseif dimensions.type == "spaced" then
		if dimensions.inner.type == "consistentSize" then
			return getVisibleRangeConsistentSize(scrollAxis, windowAxis, dimensions.inner.size + dimensions.spacing, #data)
		elseif dimensions.inner.type == "consistentUDim2" then
			return getVisibleRangeGrid(
				scrollAxis,
				windowAxis,
				dimensions.inner.udim2
					+ UDim2.fromOffset(
						if direction == "x" then dimensions.spacing else 0,
						if direction == "y" then dimensions.spacing else 0
					),
				windowSize,
				direction,
				#data
			)
		else
			error("Unsupported spaced dimensions")
		end
	else
		error("Unknown dimension type: " .. tostring(dimensions.type))
	end
end

-- Adjust position for scroll offset (port of adjustPositionToScrollAxis)
function Dimensions.adjustForScroll(position: UDim2, scrollAxis: number, direction: string): UDim2
	if direction == "x" then
		return UDim2.new(0, position.X.Offset - scrollAxis, position.Y.Scale, position.Y.Offset)
	else
		return UDim2.new(position.X.Scale, position.X.Offset, 0, position.Y.Offset - scrollAxis)
	end
end

Dimensions.getDominantAxis = getDominantAxis

return Dimensions
