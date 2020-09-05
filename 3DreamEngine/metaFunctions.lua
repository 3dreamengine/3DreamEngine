--[[
#part of the 3DreamEngine by Luke100000
functions.lua - contains library relevant functions
--]]

local lib = _3DreamEngine

--light functions
local light = {
	setBrightness = function(self, brightness)
		self.brightness = brightness
	end,
	
	setColor = function(self, r, g, b)
		if type(r) == "table" then
			r, g, b = r[1], r[2], r[3]
		end
		local v = math.sqrt(r^2+g^2+b^2)
		self.r = r / v
		self.g = g / v
		self.b = b / v
	end,
	
	setPosition = function(self, x, y, z)
		if type(x) == "table" then
			x, y, z = x[1], x[2], x[3]
		end
		self.x = x
		self.y = y
		self.z = z
	end,
}

--transformation functions
local transforms = {
	reset = function(obj)
		obj.transform = mat4:getIdentity()
		return obj
	end,

	translate = function(obj, x, y, z)
		obj.transform = obj.transform:translate(x, y, z)
		return obj
	end,

	scale = function(obj, x, y, z)
		obj.transform = obj.transform:scale(x, y, z)
		return obj
	end,

	rotateX = function(obj, rx)
		obj.transform = obj.transform:rotateX(rx)
		return obj
	end,

	rotateY = function(obj, ry)
		obj.transform = obj.transform:rotateY(ry)
		return obj
	end,

	rotateZ = function(obj, rz)
		obj.transform = obj.transform:rotateZ(rz)
		return obj
	end,

	setDirection = function(obj, normal, up)
		obj.transform = lib:lookAt(vec3(0, 0, 0), normal, up):invert() * obj.transform
		return obj
	end,
}

--shader functions
local shader = {
	activateShaderModule = function(obj, name)
		if not obj.modules then
			obj.modules = { }
		end
		obj.modules[name] = true
	end,
	
	deactivateShaderModule = function(obj, name)
		obj.modules[name] = nil
	end,
	
	isShaderModuleActive = function(obj, name)
		return obj.modules and obj.modules[name]
	end
}

--link several metatables together
local function link(...)
	local mts = {...}
	local m = {__index = mts[1]}
	for i = 2, #mts do
		m = {__index = setmetatable(mts[i], m)}
	end
	return m
end

--final meta tables
lib.meta = {
	cam = link(transforms),
	object = link(transforms, shader),
	subObject = link(shader),
	material = link(shader),
	cam = link(transforms),
	light = link(light),
}