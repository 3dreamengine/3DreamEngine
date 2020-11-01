local lib = _3DreamEngine

--creates a new set of canvas output settings
function lib:newSetSettings()
	return setmetatable({
		resolution = 512,
		format = "rgba16f",
		postEffects = false,
		msaa = 4,
		fxaa = false,
		refractions = false,
		averageAlpha = false,
		alphaPass = true,
		mode = "normal",
	}, self.meta.setSettings)
end

return {
	link = {"setSettings"},
	
	setterGetter = {
		resolution = "number",
		format = "string",
		postEffects = "boolean",
		msaa = "number",
		fxaa = "boolean",
		refractions = "boolean",
		averageAlpha = "boolean",
		alphaPass = "boolean",
		mode = "getter",
	},
	
	setMode = function(self, mode)
		assert(mode == "normal" or mode == "direct" or mode == "lite")
		self.format = mode == "normal" and "rgba16f" or "rgba8"
		self.mode = mode
	end,
}