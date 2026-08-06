local PxScale = require("@self/PxScale")
local PxCanvas = require("@self/PxCanvas")
local curve = require("@self/curve")
local px = require("@self/px")

export type Knot = curve.Knot
export type Curve = curve.Curve
export type Config = PxCanvas.Config

return {
	px = px,
	PxScale = PxScale,
	PxCanvas = PxCanvas,
	curve = curve,
}
