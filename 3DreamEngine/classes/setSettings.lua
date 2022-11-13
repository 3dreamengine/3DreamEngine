local lib = _3DreamEngine

---Creates a new set of canvas output settings
---@return DreamSetSettings
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

--todo merge setSettings and the actual set
---@class DreamSetSettings
local class = {
	links = { "setSettings" },
	
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

--todo remove lite, change to flag
---Set the output mode, normal contains all features, direct do not use a canvas at all and directly renders and lite uses a canvas but on a faster feature set
---@param mode "normal"|"lite"
---@deprecated
function class:setMode(mode)
	assert(mode == "normal" or mode == "direct" or mode == "lite")
	self.format = mode == "normal" and "rgba16f" or "rgba8"
	self.mode = mode
end
function class:getMode()
	return self.mode
end

---Sets the pixel format manually
---@param format "PixelFormat"
function class:setFormat(format)
	self.format = format
end
function class:getFormat()
	return self.mode
end

---Toggle the alpha pass
---@param alphaPass boolean
function class:setAlphaPass(alphaPass)
	self.alphaPass = alphaPass
end
function class:getAlphaPass()
	return self.alphaPass
end

---Toggle refractions
---@param refractions boolean
function class:setRefractions(refractions)
	self.refractions = refractions
end
function class:getRefractions()
	return self.refractions
end

---Toggle Fast approximate anti aliasing
---@param fxaa boolean
function class:setFXAA(fxaa)
	self.fxaa = fxaa
end
function class:getFXAA()
	return self.fxaa
end

---Set Multi Sample Anti Aliasing sample count
---@param msaa number
function class:setMSAA(msaa)
	self.msaa = msaa
end
function class:getMSAA()
	return self.msaa
end

return class