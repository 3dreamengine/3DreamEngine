local lib = _3DreamEngine

function lib:newLight(posX, posY, posZ, r, g, b, brightness, typ)
	r = r or 1.0
	g = g or 1.0
	b = b or 1.0
	local v = math.sqrt(r^2 + g^2 + b^2)
	
	local l = {
		typ = typ or "point",
		x = posX or 0,
		y = posY or 0,
		z = posZ or 0,
		r = v == 0 and 0 or r / v,
		g = v == 0 and 0 or g / v,
		b = v == 0 and 0 or b / v,
		smooth = nil,
		brightness = brightness or 1.0,
	}
	
	return setmetatable(l, self.meta.light)
end

return {
	link = {"light"},
	
	setBrightness = function(self, brightness)
		self.brightness = brightness
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
	
	setPosition = function(self, x, y, z)
		if type(x) == "table" then
			x, y, z = x[1], x[2], x[3]
		end
		self.x = x
		self.y = y
		self.z = z
	end,
	
	addShadow = function(self, shadow_static, res)
		if type(shadow_static) == "table" then
			assert(shadow_static.typ, "Provides shadow object does not seem to be a shadow.")
			self.shadow = shadow_static
			self.shadow:refresh()
		else
			self.shadow = lib:newShadow(self.typ, shadow_static or false, res)
		end
	end,
	
	setSmoothing = function(self, smooth)
		assert(type(smooth) == "boolean", "boolean expected!")
		self.smooth = smooth
	end,
}