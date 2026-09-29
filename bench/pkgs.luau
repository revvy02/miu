-- Loads a package set from a folder laid out like the dev place's ReplicatedStorage.pkgs
-- (dev.project.json): folder names are the require aliases, so the packages' relative requires
-- ("../miu") resolve inside the set. Fixtures take the set they render with, so A/B runs can
-- render the same fixture against two independent copies of miu.
export type Pkgs = { miu: any, wind: any, transition: any }

return function(folder: Instance): Pkgs
	return {
		miu = require(folder:FindFirstChild("miu") :: ModuleScript),
		wind = require(folder:FindFirstChild("miu_wind") :: ModuleScript),
		transition = require(folder:FindFirstChild("miu_transition") :: ModuleScript),
	}
end
