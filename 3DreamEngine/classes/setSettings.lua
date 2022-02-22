local lib = _3DreamEngine

--creates a new set of canvas output settings
function lib:newSetSettings()
	return setmetatable({
		resolution = 512,
		format = "rgba16f",
		msaa = 4,
		fxaa = false,
		refractions = false,
		alphaPass = true,
		mode = "normal",
	}, self.meta.setSettings)
end

local class = {
	link = {"setSettings"},
	
	setterGetter = {
		resolution = "number",
		format = "string",
		msaa = "number",
		fxaa = "boolean",
		refractions = "boolean",
		alphaPass = "boolean",
		mode = "getter",
	},
}

function class:setMode(mode)
	assert(mode == "normal" or mode == "direct" or mode == "lite")
	self.format = mode == "normal" and "rgba16f" or "rgba8"
	self.mode = mode
end

function class:getRefractions()
	return self.refractions
end

function class:getAlphaPass()
	return self.alphaPass
end

return class