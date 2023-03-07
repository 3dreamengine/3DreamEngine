---@type Dream
local lib = _3DreamEngine

function lib:newEmptyBoundingSphere()
	return setmetatable({
		first = vec3(math.huge, math.huge, math.huge),
		second = vec3(-math.huge, -math.huge, -math.huge),
		center = vec3(0.0, 0.0, 0.0),
		size = 0
	}, self.meta.boundingSphere)
end

function lib:newBoundingSphere(center, size)
	return setmetatable({
		center = center,
		size = size
	}, self.meta.boundingSphere)
end

---@class DreamBoundingSphere
---@field public center "vec3"
---@field public size number"
local class = {
	links = { "clone", "boundingSphere" },
}

function class:decode()
	self.center = vec3(self.center)
end

---Merge with a second bounding sphere
---@param other DreamBoundingSphere
---@return DreamBoundingSphere
function class:merge(other)
	if not self:isInitialized() then
		return other
	end
	
	local diff = other.center - self.center
	local dist = diff:length()
	if dist <= self.size - other.size then
		return self
	end
	if dist <= other.size - self.size then
		return other
	end
	
	local R = (self.size + other.size + dist) / 2
	local C = self.center + diff * (R - self.size) / dist
	
	return lib:newBoundingSphere(C, R)
end

---Extend bounding sphere
---@param margin number
---@return DreamBoundingSphere
function class:extend(margin)
	return lib:newBoundingSphere(self.center, self.size + margin)
end

---Test if two bounding spheres intersect
---@param other DreamBoundingSphere
---@return boolean
function class:intersect(other)
	return (self.center - other.center):lengthSquared() < (self.size + other.size) ^ 2
end

---@return boolean
function class:isInitialized()
	return self.size > 0
end

---@return "vec3"
function class:getCenter()
	return self.center
end

---@return number
function class:getSize()
	return self.size
end

function class:tostring()
	return string.format("boundingSphere(center = %s, size = %f)", self.center, self.size)
end

return class