---@type Dream
local lib = _3DreamEngine
local vec3 = lib.vec3

---Creates new light source
---@param typ string @ "point" or "sun"
---@param position DreamVec3
---@param color number[]
---@param brightness number
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
		
		--todo technically not related to light sources at all, should only care about brightness and size
		godray = false,
		godrayLength = typ == "sun" and 0.1 or 0.05,
		godraySize = typ == "sun" and 0.1 or 0.035,
	}
	
	return setmetatable(l, self.meta.light)
end

---A light source.
---@class DreamLight : DreamClonable, DreamIsNamed
local class = {
	links = { "light", "clonable", "named" },
}

---@private
function class:tostring()
	return string.format("%s (%.3f brightness)", self.name, self.brightness)
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

--todo
---@deprecated
function class:setGodrays(e)
	self.godrays = e
end
---@deprecated
function class:getGodrays()
	return self.godrays
end

function class:setBrightness(brightness)
	self.brightness = brightness
end
function class:getBrightness()
	return self.brightness
end

---Sets the color, should roughly be a unit vector
---@param r number
---@param g number
---@param b number
function class:setColor(r, g, b)
	self.color = vec3(r, g, b)
end
function class:getColor()
	return self.color
end

---Set the position for point sources
---@param x number
---@param y number
---@param z number
function class:setPosition(x, y, z)
	self.position = vec3(x, y, z)
end
function class:getPosition()
	return self.position
end

---Set the direction for sun light sources
---@param x number
---@param y number
---@param z number
function class:setDirection(x, y, z)
	self.direction = vec3(x, y, z):normalize()
end
function class:getDirection()
	return self.direction
end

---Assign a shadow to this light source, a shadow can be shared by light sources if close to each other
---@param shadow DreamShadow
function class:addShadow(shadow)
	assert(shadow and shadow.typ, "Provided shadow object does not seem to be a shadow.")
	if lib.canvasFormats["r16f"] then
		self.shadow = shadow
		self.shadow:refresh()
	else
		print("Attempt to use a shadow without r16f support, shadow is ignored.")
	end
end

---Creates a new shadow with given resolution
---@param resolution number
function class:addNewShadow(resolution)
	local shadow = lib:newShadow(self.typ, resolution)
	self:addShadow(shadow)
	return shadow
end

---@return DreamShadow
function class:getShadow()
	return self.shadow
end

---@private
function class:decode()
	self.position = vec3(self.position)
	self.direction = vec3(self.direction)
	self.color = vec3(self.color)
end

return class