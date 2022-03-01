local lib = _3DreamEngine

function lib:newLight(typ, pos, color, brightness)
	local l = {
		typ = typ or "point",
		name = "unnamed",
		pos = pos or vec3(0, 0, 0),
		size = 0.05,
		color = color and color:normalize() or vec3(1, 1, 1),
		direction = vec3(1, 1, 1):normalize(),
		brightness = brightness or 1.0,
		attenuation = 2.0,
		
		godray = false,
		godrayLength = typ == "sun" and 0.1 or 0.05,
		godraySize = typ == "sun" and 0.1 or 0.035,
	}
	
	return setmetatable(l, self.meta.light)
end

local class = {
	link = {"light", "clone"},
	
	setterGetter = {
		name = "string",
		size = "number",
		attenuation = "number",
		godrayLength = "number",
		godraySize = "number",
	},
}

function class:tostring()
	return string.format("%s (%.3f brightness)", self.name, self.brightness)
end

function class:setName(name)
	self.name = lib:removePostfix(name)
end

function class:setGodrays(e)
	self.godrays = e
end
function class:getGodrays()
	return self.godrays
end

function class:setBrightness(brightness)
	self.brightness = brightness
end
function class:getBrightness()
	return self.brightness
end

function class:setColor(r, g, b)
	self.color = vec3(r, g, b):normalize()
end
function class:getColor()
	return self.color
end

function class:setPosition(x, y, z)
	self.pos = vec3(x, y, z)
end
function class:getPosition()
	return self.pos
end

function class:setDirection(x, y, z)
	self.direction = vec3(x, y, z):normalize()
end
function class:getDirection()
	return self.direction
end

function class:addShadow(res)
	if type(res) == "table" then
		assert(res.typ, "Provided shadow object does not seem to be a shadow.")
		self.shadow = res
		self.shadow:refresh()
	else
		self.shadow = lib:newShadow(self.typ, res)
	end
end

function class:setShadow(shadow)
	self.shadow = shadow
end
function class:getShadow()
	return self.shadow
end

function class:decode()
	self.pos = vec3(self.pos)
	self.direction = vec3(self.direction)
	self.color = vec3(self.color)
end

return class