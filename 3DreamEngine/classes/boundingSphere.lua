---@type Dream
local lib = _3DreamEngine

function lib:newEmptyBoundingSphere()
	return setmetatable({
		first = vec3(math.huge, math.huge, math.huge),
		second = vec3(-math.huge, -math.huge, -math.huge),
		center = vec3(0.0, 0.0, 0.0),
		size = 0,
		initialized = false
	}, self.meta.boundingSphere)
end

function lib:newBoundingSphere(center, size)
	return setmetatable({
		center = center,
		size = size,
		initialized = true
	}, self.meta.boundingSphere)
end

---@class DreamBoundingSphere
---@field center "vec3"
---@field size number"
local class = {
	links = { "clone", "boundingSphere" },
}

function class:decode()
	self.center = vec3(self.center)
end

---Merge with a second bounding sphere
---@param other DreamBoundingSphere
function class:merge(other)
	local diff = other.center - self.center
	local dist = diff:length()
	if dist < self.size - other.size then
		return self
	end
	if dist < other.size - self.size then
		return other
	end
	
	local R = (self.size + other.size + dist) / 2
	local C = self.center + diff * (R - self.size) / diff
	
	return lib:newBoundingSphere(C, R)
end

---Extend bounding sphere
---@param margin number
function class:extend(margin)
	return lib:newBoundingSphere(self.center, self.size + margin)
end

---Test if two bounding spherees intersect
---@param other DreamBoundingSphere
function class:intersect(other)
	return (self.center - other.center):lengthSquared() < (self.size + other.size) ^ 2
end

function class:setInitialized(b)
	self.initialized = b
end

---@return boolean
function class:isInitialized()
	return self.initialized
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