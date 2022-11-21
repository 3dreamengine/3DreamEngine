local I = mat4.getIdentity()

---@class DreamTransformable
local class = { }

function class:resetTransform()
	self.transform = false
	return self
end

function class:setTransform(t)
	self.transform = t
	self.inverseTransform = false
	self.dynamic = true
	return self
end

function class:getTransform()
	return self.transform or I
end

function class:translate(x, y, z)
	self.transform = self.transform and self.transform:translate(x, y, z) or mat4.getTranslate(x, y, z)
	self.inverseTransform = false
	self.dynamic = true
	return self
end

function class:scale(x, y, z)
	self.transform = self.transform and self.transform:scale(x, y, z) or mat4.getScale(x, y, z)
	self.inverseTransform = false
	self.dynamic = true
	return self
end

function class:rotateX(rx)
	self.transform = self.transform and self.transform:rotateX(rx) or mat4.getRotateX(rx)
	self.inverseTransform = false
	self.dynamic = true
	return self
end

function class:rotateY(ry)
	self.transform = self.transform and self.transform:rotateY(ry) or mat4.getRotateY(ry)
	self.inverseTransform = false
	self.dynamic = true
	return self
end

function class:rotateZ(rz)
	self.transform = self.transform and self.transform:rotateZ(rz) or mat4.getRotateZ(rz)
	self.inverseTransform = false
	self.dynamic = true
	return self
end

--todo optimize world transforms
function class:translateWorld(x, y, z)
	self.transform = self.transform and (mat4.getTranslate(x, y, z) * self.transform) or mat4.getTranslate(x, y, z)
	self.inverseTransform = false
	self.dynamic = true
	return self
end

function class:scaleWorld(x, y, z)
	self.transform = self.transform and (mat4.getScale(x, y, z) * self.transform) or mat4.getScale(x, y, z)
	self.inverseTransform = false
	self.dynamic = true
	return self
end

function class:rotateXWorld(rx)
	self.transform = self.transform and (mat4.getRotateX(rx) * self.transform) or mat4.getRotateX(rx)
	self.inverseTransform = false
	self.dynamic = true
	return self
end

function class:rotateYWorld(ry)
	self.transform = self.transform and (mat4.getRotateY(ry) * self.transform) or mat4.getRotateY(ry)
	self.inverseTransform = false
	self.dynamic = true
	return self
end

function class:rotateZWorld(rz)
	self.transform = self.transform and (mat4.getRotateZ(rz) * self.transform) or mat4.getRotateZ(rz)
	self.inverseTransform = false
	self.dynamic = true
	return self
end

function class:getPosition()
	local t = self:getTransform()
	return vec3(t[4], t[8], t[12])
end

function class:lookAt(position, up)
	position = self:getInvertedTransform() * position
	up = self:getInvertedTransform():subm() * (up or vec3(0.0, 1.0, 0.0))
	self:lookTowards(position, up)
end

function class:lookTowards(direction, up)
	up = up or vec3(0.0, 1.0, 0.0)
	
	local zaxis = direction:normalize()
	local xaxis = zaxis:cross(up):normalize()
	local yaxis = xaxis:cross(zaxis)
	
	local rotate = mat4({
		xaxis.x, xaxis.y, xaxis.z, 0.0,
		yaxis.x, yaxis.y, yaxis.z, 0.0,
		-zaxis.x, -zaxis.y, -zaxis.z, 0.0,
		0, 0, 0, 1
	})
	
	--todo someone with better math skills should take a look at this mess
	self.transform = self:getTransform() * rotate:invert()
	
	self.inverseTransform = false
	self.dynamic = true
	return self
end

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

function class:setDynamic(dynamic)
	self.dynamic = dynamic or false
end
function class:isDynamic()
	return self.dynamic
end

return class