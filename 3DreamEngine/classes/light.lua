local lib = _3DreamEngine

---@return DreamLight
function lib:newLight(typ, position, color, brightness)
	local l = {
		typ = typ or "point",
		name = "unnamed",
		position = position or vec3(0, 0, 0),
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

---@class DreamLight
local class = {
	links = { "light", "clone" },
}

function class:tostring()
	return string.format("%s (%.3f brightness)", self.name, self.brightness)
end

---@param name string
function class:setName(name)
	self.name = lib:removePostfix(name)
end
function class:getName()
	return self.name
end

---The size mostly affects smooth lighting
---@param size number
function class:setSize(size)
	self.size = size
end
function class:getSize()
	return self.size
end

---The attenuation exponent should be 2.0 for realism, but higher values produce a more cozy, artistic result
---@param attenuation number
function class:setAttenuation(attenuation)
	self.attenuation = attenuation
end
function class:getAttenuation()
	return self.attenuation
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
	self.color = vec3(r, g, b)
end
function class:getColor()
	return self.color
end

function class:setPosition(x, y, z)
	self.position = vec3(x, y, z)
end
function class:getPosition()
	return self.position
end

function class:setDirection(x, y, z)
	self.direction = vec3(x, y, z):normalize()
end
function class:getDirection()
	return self.direction
end

---@param shadow DreamShadow
function class:addShadow(shadow)
	assert(shadow and shadow.typ, "Provided shadow object does not seem to be a shadow.")
	self.shadow = shadow
	self.shadow:refresh()
end

---Creates a new shadow with given resolution
---@param resolution number
function class:addNewShadow(resolution)
	self.shadow = lib:newShadow(self.typ, resolution)
end

---@return DreamShadow
function class:getShadow()
	return self.shadow
end

function class:decode()
	self.position = vec3(self.position)
	self.direction = vec3(self.direction)
	self.color = vec3(self.color)
end

return class