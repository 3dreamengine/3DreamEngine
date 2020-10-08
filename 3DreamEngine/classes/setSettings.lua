local lib = _3DreamEngine

--creates a new set of canvas output settings
function lib:newSetSettings()
	return setmetatable({
		resolution = 512,
		format = "rgba16f",
		deferred = false,
		direct = false,
		postEffects = false,
		msaa = 4,
		fxaa = false,
	}, self.meta.setSettings)
end

return {
	link = {"setSettings"},
	
	setterGetter = {
		resolution = "number",
		format = "string",
		deferred = "boolean",
		postEffects = "boolean",
		direct = "boolean",
		msaa = "number",
		fxaa = "boolean",
	},
}