local lib = _3DreamEngine

local function removePostfix(t)
	local v = t:match("(.*)%.[^.]+")
	return v or t
end

local convertOldLight = function(x, y, z, r, g, b, brightness)
	return vec3(x or 0, y or 0, z or 0), vec3(r or 1, g or 1, b or 1), brightness or 1
end

function lib:newLight(typ, pos, color, brightness, old, ...)
	--backwards compatibility
	if old then
		pos, color, brightness = convertOldLight(pos, color, brightness, old, ...)
	end
	
	local l = {
		typ = typ or "point",
		name = "unnamed",
		pos = pos or vec3(0, 0, 0),
		color = color and color:normalize() or vec3(1, 1, 1),
		direction = vec3(0, -1, 0),
		smooth = nil,
		frameSkip = 0,
		brightness = brightness or 1.0,
		godray = nil,
		godrayLength = typ == "sun" and 0.15 or 0.05,
		godraySize = typ == "sun" and 0.1 or 0.035,
	}
	
	return setmetatable(l, self.meta.light)
end

return {
	link = {"light", "clone"},
	
	setterGetter = {
		frameSkip = "number",
		name = "string",
		godrayLength = "number",
		godraySize = "number",
	},
	
	setName = function(self, name)
		self.name = removePostfix(name)
	end,
	
	setGodrays = function(self, e)
		self.godrays = e
	end,
	getGodrays = function(self)
		return self.godrays
	end,
	
	setBrightness = function(self, brightness)
		self.brightness = brightness
	end,
	getBrightness = function(self)
		return self.brightness
	end,
	
	setColor = function(self, r, g, b)
		self.color = vec3(r, g, b):normalize()
	end,
	getColor = function(self)
		return self.color
	end,
	
	setPosition = function(self, x, y, z)
		self.pos = vec3(x, y, z)
	end,
	getPosition = function(self)
		return self.pos
	end,
	
	setDirection = function(self, x, y, z)
		self.direction = vec3(x, y, z):normalize()
	end,
	getDirection = function(self)
		return self.direction
	end,
	
	addShadow = function(self, static, res)
		if type(static) == "table" then
			assert(static.typ, "Provides shadow object does not seem to be a shadow.")
			self.shadow = static
			self.shadow:refresh()
		else
			self.shadow = lib:newShadow(self.typ, static or false, res)
		end
	end,
	
	setSmoothing = function(self, smooth)
		assert(type(smooth) == "boolean", "boolean expected!")
		self.smooth = smooth
	end,
	getSmoothing = function(self)
		return self.smooth
	end,
	
	setShadow = function(self, shadow)
		self.shadow = shadow
	end,
	getShadow = function(self)
		return self.shadow
	end,
}