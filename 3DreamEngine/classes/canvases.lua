local lib = _3DreamEngine

---Creates a new set of canvas outputs
---@return DreamCanvases
function lib:newCanvases()
	return setmetatable({
		resolution = 512,
		format = "rgba16f",
		msaa = 4,
		fxaa = false,
		refractions = false,
		alphaPass = true,
		mode = "normal",
	}, self.meta.canvases)
end

---@class DreamCanvases
local class = {
	links = { "canvases" },
}

---Set the output mode, normal contains all features, direct do not use a canvas at all and directly renders and lite uses a canvas but on a faster feature set
---@param mode "normal"|"direct"|"lite"
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

---Initialize that canvas set
---@param w number @ optional
---@param h number @ optional
function class:init(w, h)
	self:unloadCanvasSet()
	
	w = w or self.resolution
	h = h or self.resolution
	
	--settings
	self.width = w
	self.height = h
	self.refractions = self.alphaPass and self.refractions and self.mode == "normal"
	
	if self.mode ~= "direct" then
		--depth
		self.depthBuffer = love.graphics.newCanvas(w, h, { format = lib.canvasFormats["depth32f"] and "depth32f" or lib.canvasFormats["depth24"] and "depth24" or "depth16", readable = false, msaa = self.msaa })
		
		--temporary HDR color
		self.color = love.graphics.newCanvas(w, h, { format = self.format, readable = true, msaa = self.msaa })
		
		--additional color if using refractions
		if self.refractions then
			self.colorAlpha = love.graphics.newCanvas(w, h, { format = "rgba16f", readable = true, msaa = self.msaa })
			self.distortion = love.graphics.newCanvas(w, h, { format = "rg16f", readable = true, msaa = self.msaa })
		end
		
		--depth
		self.depth = love.graphics.newCanvas(w, h, { format = "r16f", readable = true, msaa = self.msaa })
	end
	
	--screen space ambient occlusion blurring canvases
	if lib.AO_enabled and self.mode ~= "direct" then
		self.AO_1 = love.graphics.newCanvas(w * lib.AO_resolution, h * lib.AO_resolution, { format = "r8", readable = true, msaa = 0 })
		if lib.AO_blur then
			self.AO_2 = love.graphics.newCanvas(w * lib.AO_resolution, h * lib.AO_resolution, { format = "r8", readable = true, msaa = 0 })
		end
	end
	
	--post effects
	if self.mode == "normal" then
		--bloom blurring canvases
		if lib.bloom_enabled then
			self.bloom_1 = love.graphics.newCanvas(w * lib.bloom_resolution, h * lib.bloom_resolution, { format = self.format, readable = true, msaa = 0 })
			self.bloom_2 = love.graphics.newCanvas(w * lib.bloom_resolution, h * lib.bloom_resolution, { format = self.format, readable = true, msaa = 0 })
		end
	end
	
	return self
end

---Unload canvases
function class:unloadCanvasSet()
	for _, s in pairs(self) do
		if type(s) == "userdata" and s.release then
			s:release()
		end
	end
end

return class