local lib = _3DreamEngine

function lib:newEmptyBoundingBox()
	return setmetatable({
		first = vec3(math.huge, math.huge, math.huge),
		second = vec3(-math.huge, -math.huge, -math.huge),
		center = vec3(0.0, 0.0, 0.0),
		size = 0,
		initialized = false
	}, self.meta.boundingBox)
end

function lib:newBoundingBox(first, second, center, size)
	center = center or (second - first) / 2
	return setmetatable({
		first = first,
		second = second,
		center = center,
		size = size or (center - first):length() * math.sqrt(3),
		initialized = true
	}, self.meta.boundingBox)
end

---@class DreamBoundingBox
local class = {
	links = { "clone", "boundingBox" },
}

function class:decode()
	self.first = vec3(self.first)
	self.second = vec3(self.second)
	self.center = vec3(self.center)
end

---Merge with a second bounding box
---@param boundingBox DreamBoundingBox
function class:merge(boundingBox)
	--todo bounding spheres not merged efficiently
	return lib:newBoundingBox(
			self.first:max(boundingBox.first),
			self.second:max(boundingBox.second),
			(self.center + boundingBox.center) / 2
	)
end

---Extend bounding box
---@param margin number
function class:extend(margin)
	local m = vec3(margin, margin, margin)
	return lib:newBoundingBox(self.first - m, self.second + m, self.center, self.size)
end

function class:setInitialized(b)
	self.initialized = b
end

---@return boolean
function class:isInitialized()
	return self.initialized
end

---@return "vec3"
function class:getFirst()
	return self.first
end

---@return "vec3"
function class:getSecond()
	return self.second
end

---@return "vec3"
function class:getCenter()
	return self.center
end

---@return number
function class:getSize()
	return self.size
end

return class