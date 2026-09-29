-- The packages as the dev place mounts them (dev.project.json). Fixtures require them through the
-- DOM because the packages' relative requires only resolve in that layout, not on disk.
local pkgs = game:GetService("ReplicatedStorage").pkgs

return {
	miu = require(pkgs.miu),
	wind = require(pkgs.miu_wind),
	transition = require(pkgs.miu_transition),
}
