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
		size = 0.1,
		color = color and color:normalize() or vec3(1, 1, 1),
		direction = vec3(1, 1, 1),
		brightness = brightness or 1.0,
		
		godray = nil,
		godrayLength = typ == "sun" and 0.15 or 0.05,
		godraySize = typ == "sun" and 0.1 or 0.035,
	}
	
	return setmetatable(l, self.meta.light)
end

local class = {
	link = {"light", "clone"},
	
	setterGetter = {
		name = "string",
		size = "number",
		godrayLength = "number",
		godraySize = "number",
	},
}

function class:tostring()
	return string.format("%s (%.3f brightness)", self.name, self.brightness)
end

function class:setName(name)
	self.name = removePostfix(name)
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

function class:addShadow(static, res)
	if type(static) == "table" then
		assert(static.typ, "Provides shadow object does not seem to be a shadow.")
		self.shadow = static
		self.shadow:refresh()
	else
		self.shadow = lib:newShadow(self.typ, static or false, res)
	end
end

function class:setShadow(shadow)
	self.shadow = shadow
end
function class:getShadow()
	return self.shadow
end

return class