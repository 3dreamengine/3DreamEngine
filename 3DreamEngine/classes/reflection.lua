---@type Dream
local lib = _3DreamEngine
local vec3 = lib.vec3

---@return DreamReflection
function lib:newReflection(static, resolution, roughness, lazy)
	roughness = roughness ~= false
	
	assert(not resolution or self.reflectionCanvases.mode ~= "direct", "Custom reflection resolutions are too expensive unless direct render on them has been enabled.")
	resolution = resolution or self.reflectionCanvases.resolution
	
	local canvas, image
	if type(static) == "userdata" then
		--use loaded cubemap
		image = static
		static = true
	else
		--create new canvas
		canvas = love.graphics.newCanvas(resolution, resolution,
				{ format = self.reflections_format, readable = true, msaa = 0, type = "cube", mipmaps = roughness and "manual" or "none" })
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

---A reflection globe, updated when visible. Dynamic globes are slow and should be used with care. In many cases, static globes are sufficient.
---@class DreamReflection
local class = {
	links = { "reflection" },
}

---Request a rerender, especially relevant if the globe is static
function class:refresh()
	self.done = false
end

---Set the bounds of the globe. A local globe is more accurate for objects close to the bounds.
---@param center DreamVec3
---@param first DreamVec3
---@param second DreamVec3
function class:setLocal(center, first, second)
	--todo change to matrix and offset (where offset, e.g. center is probably redundant)
	self.center = center
	self.first = first
	self.second = second
end
function class:getLocal()
	return self.center, self.first, self.second
end

---Lazy reflections spread the load over several frames and are therefore much faster at the cost of a bit of flickering
---@param lazy boolean
function class:setLazy(lazy)
	self.lazy = lazy
end
function class:getLazy()
	return self.lazy
end

---@private
function class:decode()
	self.center = vec3(self.center)
	self.first = vec3(self.first)
	self.second = vec3(self.second)
end

return class