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

--sene functions
local white = vec4(1.0, 1.0, 1.0, 1.0)
local scene = {
	clear = function(self)
		self.tasks = { }
	end,
	
	add = function(self, obj, transform, col)
		if not transform then
			transform = obj.transform
		end
		
		--add to scene
		for d,s in pairs(obj.objects or {obj}) do
			if s.mesh and not s.disabled then
				--get required shader
				s.shader = lib:getShaderInfo(s, obj)
				
				--bounding box
				local pos
				local bb = s.boundingBox
				if bb then
					--mat4 * vec3 multiplication, for performance reasons hardcoded
					local a = bb.center
					pos = vec3(transform[1] * a[1] + transform[2] * a[2] + transform[3] * a[3] + transform[4],
						transform[5] * a[1] + transform[6] * a[2] + transform[7] * a[3] + transform[8],
						transform[9] * a[1] + transform[10] * a[2] + transform[11] * a[3] + transform[12])
				else
					pos = vec3(transform[4], transform[8], transform[12])
				end
				
				--add
				table.insert(self.tasks, {
					transform = transform, --transformation matrix, can be nil
					pos = pos,             --bounding box center position of object
					s = s,                 --drawable object
					color = col or white,  --color, will affect color/albedo input
					obj = obj,             --the object container used to store general informations (reflections, ...)
					boneTransforms = obj.boneTransforms,
				})
			end
		end
	end,
}

print("visibility functions not implemented yet")
local visibility = {
	setLoD = function(self, map)
		
	end,
	setLoDDistance = function(self, distance)
		
	end,
	setVisibility = function(self, render, shadow, reflections)
		
	end,
}

--link several metatables together
local function link(...)
	local m = { }
	for _,meta in pairs({...}) do
		for name, func in pairs(meta) do
			m[name] = func
		end
	end
	return {__index = m}
end

--final meta tables
lib.meta = {
	cam = link(transforms),
	object = link(transforms, shader, visibility),
	subObject = link(shader, visibility),
	material = link(shader),
	cam = link(transforms),
	light = link(light),
	scene = link(scene, visibility),
}