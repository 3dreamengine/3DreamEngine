local lib = _3DreamEngine

local function removePostfix(t)
	local v = t:match("(.*)%.[^.]+")
	return v or t
end

function lib:newLight(typ, posX, posY, posZ, r, g, b, brightness)
	r = r or 1.0
	g = g or 1.0
	b = b or 1.0
	local v = math.sqrt(r^2 + g^2 + b^2)
	
	local l = {
		typ = typ or "point",
		name = "unnamed",
		x = posX or 0,
		y = posY or 0,
		z = posZ or 0,
		r = v == 0 and 0 or r / v,
		g = v == 0 and 0 or g / v,
		b = v == 0 and 0 or b / v,
		smooth = nil,
		frameSkip = 0,
		brightness = brightness or 1.0,
	}
	
	return setmetatable(l, self.meta.light)
end

return {
	link = {"light", "clone"},
	
	setterGetter = {
		frameSkip = "number",
		name = "string",
	},
	
	setName = function(self, name)
		self.name = removePostfix(name)
	end,
	
	setBrightness = function(self, brightness)
		self.brightness = brightness
	end,
	getBrightness = function(self)
		return self.brightness
	end,
	
	setColor = function(self, r, g, b)
		if type(r) == "table" then
			r, g, b = r[1], r[2], r[3]
		end
		local v = math.sqrt(r^2 + g^2 + b^2)
		self.r = v == 0 and 0 or r / v
		self.g = v == 0 and 0 or g / v
		self.b = v == 0 and 0 or b / v
	end,
	getColor = function(self)
		return self.r, self.g, self.b
	end,
	
	setPosition = function(self, x, y, z)
		if type(x) == "table" then
			x, y, z = x[1], x[2], x[3]
		end
		self.x = x
		self.y = y
		self.z = z
	end,
	getPosition = function(self)
		return self.x, self.y, self.z
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