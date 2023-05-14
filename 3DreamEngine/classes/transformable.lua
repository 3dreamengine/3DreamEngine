local I = _3DreamEngine.mat4.getIdentity()

local vec3, mat4 = _3DreamEngine.vec3, _3DreamEngine.mat4

---@class DreamTransformable
local class = { }

---Resets the transform to the identify matrix
---@return DreamTransformable
function class:resetTransform()
	self.transform = false
	return self
end

---@param transform DreamMat4
---@return DreamTransformable
function class:setTransform(transform)
	self.transform = transform
	self:setDirty()
	return self
end

---Gets the current, local transformation matrix
---@return DreamMat4
function class:getTransform()
	return self.transform or I
end

---Translate in local coordinates
---@param x number
---@param y number
---@param z number
---@return DreamTransformable
function class:translate(x, y, z)
	self.transform = self.transform and self.transform:translate(x, y, z) or mat4.getTranslate(x, y, z)
	self:setDirty()
	return self
end

---Scale in local coordinates
---@param x number
---@param y number
---@param z number
---@return DreamTransformable
function class:scale(x, y, z)
	self.transform = self.transform and self.transform:scale(x, y, z) or mat4.getScale(x, y, z)
	self:setDirty()
	return self
end

---Euler rotation around the X axis in local coordinates
---@param rx number
---@return DreamTransformable
function class:rotateX(rx)
	self.transform = self.transform and self.transform:rotateX(rx) or mat4.getRotateX(rx)
	self:setDirty()
	return self
end

---Euler rotation around the Y axis in local coordinates
---@param ry number
---@return DreamTransformable
function class:rotateY(ry)
	self.transform = self.transform and self.transform:rotateY(ry) or mat4.getRotateY(ry)
	self:setDirty()
	return self
end

---Euler rotation around the Z axis in local coordinates
---@param rz number
---@return DreamTransformable
function class:rotateZ(rz)
	self.transform = self.transform and self.transform:rotateZ(rz) or mat4.getRotateZ(rz)
	self:setDirty()
	return self
end

---Translate in world coordinates
---@param x number
---@param y number
---@param z number
---@return DreamTransformable
function class:translateWorld(x, y, z)
	self.transform = self.transform and (mat4.getTranslate(x, y, z) * self.transform) or mat4.getTranslate(x, y, z)
	self:setDirty()
	return self
end

---Scale in world coordinates
---@param x number
---@param y number
---@param z number
---@return DreamTransformable
function class:scaleWorld(x, y, z)
	self.transform = self.transform and (mat4.getScale(x, y, z) * self.transform) or mat4.getScale(x, y, z)
	self:setDirty()
	return self
end

---Euler rotation around the X axis in world coordinates
---@param rx number
---@return DreamTransformable
function class:rotateXWorld(rx)
	self.transform = self.transform and (mat4.getRotateX(rx) * self.transform) or mat4.getRotateX(rx)
	self:setDirty()
	return self
end

---Euler rotation around the Y axis in world coordinates
---@param ry number
---@return DreamTransformable
function class:rotateYWorld(ry)
	self.transform = self.transform and (mat4.getRotateY(ry) * self.transform) or mat4.getRotateY(ry)
	self:setDirty()
	return self
end

---Euler rotation around the Z axis in world coordinates
---@param rz number
---@return DreamTransformable
function class:rotateZWorld(rz)
	self.transform = self.transform and (mat4.getRotateZ(rz) * self.transform) or mat4.getRotateZ(rz)
	self:setDirty()
	return self
end

---Gets the current world position
---@return DreamVec3
function class:getPosition()
	local t = self:getTransform()
	return vec3(t[4], t[8], t[12])
end

---Makes the object look at the target position with given up vector
---@return DreamTransformable
function class:lookAt(position, up)
	position = self:getInvertedTransform() * position
	up = self:getInvertedTransform():subm() * (up or vec3(0.0, 1.0, 0.0))
	self:lookTowards(position, up)
	return self
end

---Marks as modified
function class:setDirty()
	self.inverseTransform = false
	self.dynamic = true
end

---Gets the last global transform. Needs to be rendered once, and if rendered multiple times, the result is undefined
---@return DreamMat4
---@beta may change
function class:getGlobalTransform()
	return self.globalTransform
end

---Look towards the global direction and upwards vector
---@param direction DreamVec3
---@param up DreamVec3
function class:lookTowards(direction, up)
	up = up or vec3(0.0, 1.0, 0.0)
	
	local zaxis = direction:normalize()
	local xaxis = zaxis:cross(up):normalize()
	local yaxis = xaxis:cross(zaxis)
	
	local rotate = mat4({
		xaxis.x, yaxis.x, -zaxis.x, 0.0,
		xaxis.y, yaxis.y, -zaxis.y, 0.0,
		xaxis.z, yaxis.z, -zaxis.z, 0.0,
		0, 0, 0, 1
	})
	
	self.transform = self:getTransform() * rotate
	
	self:setDirty()
	return self
end

---Returns the cached inverse of the local transformation
---@return DreamMat4
function class:getInvertedTransform()
	if not self.inverseTransform then
		if self.transform then
			self.inverseTransform = self.transform:invert()
		else
			return I
		end
	end
	return self.inverseTransform
end

---Dynamic objects are excluded from static shadows and reflections. Applying a transforms sets this flag automatically.
---@param dynamic boolean
function class:setDynamic(dynamic)
	self.dynamic = dynamic or false
end

---Returns weather this object is excluded from statis shadows and reflections
---@return boolean
function class:isDynamic()
	return self.dynamic
end

return class