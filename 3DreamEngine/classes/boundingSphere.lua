---@type Dream
local lib = _3DreamEngine
local vec3 = lib.vec3

---Creates a new bounding sphere
---@param center DreamVec3  @ optional
---@param size number  @ optional
function lib:newBoundingSphere(center, size)
	return setmetatable({
		center = center or vec3(0.0, 0.0, 0.0),
		size = size or 0
	}, self.meta.boundingSphere)
end

---A bounding sphere is a sphere enclosing e.g. mesh data and may be used for frustum culling
---@class DreamBoundingSphere
---@field public center DreamVec3
---@field public size number
local class = {
	links = { "clonable", "boundingSphere" },
}

---@private
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

---@return DreamVec3
function class:getCenter()
	return self.center
end

---@return number
function class:getSize()
	return self.size
end

---@private
function class:tostring()
	return string.format("boundingSphere(center = %s, size = %f)", self.center, self.size)
end

return class