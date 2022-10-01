local lib = _3DreamEngine

function lib:newReflection(static, resolution, roughness, lazy)
	roughness = roughness ~= false
	
	assert(not resolution or self.reflectionsSet.mode ~= "direct", "Custom reflection resolutions are too expensive unless direct render on them has been enabled.")
	resolution = resolution or self.reflectionsSet.resolution
	
	local canvas, image
	if type(static) == "userdata" then
		--use loaded cubemap
		image = static
		static = true
	else
		--create new canvas
		canvas = love.graphics.newCanvas(resolution, resolution,
			{format = self.reflections_format, readable = true, msaa = 0, type = "cube", mipmaps = roughness and "manual" or "none"})
	end
	
	return setmetatable({
		canvas = canvas,
		image = image,
		static = static or false,
		rendered = false,
		center = false,
		first = false,
		second = false,
		levels = false,
		roughness = roughness,
		lazy = lazy,
		id = math.random(), --used for the job render
	}, self.meta.reflection)
end

local class = {
	link = {"reflection"},
	
	setterGetter = {
		lazy = "boolean"
	}
}

function class:refresh()
	self.done = false
end

function class:setLocal(center, first, second)
	self.center = center
	self.first = first
	self.second = second
end
function class:getLocal()
	return self.center, self.first, self.second
end

function class:decode()
	self.center = vec3(self.center)
	self.first = vec3(self.first)
	self.second = vec3(self.second)
end

return class