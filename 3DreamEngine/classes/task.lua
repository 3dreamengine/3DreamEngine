local identityMatrix = mat4:getIdentity()

return {
	link = {"task"},
	
	getTransform = function(self)
		return self[1] or identityMatrix
	end,
	
	getPos = function(self)
		if not self[2] then
			local bb = self[4].boundingBox
			local transform = self[1]
			if transform then
				--mat4 * vec4(vec3, 1) multiplication, for performance reasons hardcoded
				local a = bb.center
				self[2] = vec3(transform[1] * a[1] + transform[2] * a[2] + transform[3] * a[3] + transform[4],
					transform[5] * a[1] + transform[6] * a[2] + transform[7] * a[3] + transform[8],
					transform[9] * a[1] + transform[10] * a[2] + transform[11] * a[3] + transform[12])
			else
				self[2] = bb.center
			end
		end
		return self[2]
	end,
	
	getSize = function(self)
		if not self[3] then
			local m = self[1]
			local scale = m and math.max(
				(m[1]^2 + m[5]^2 + m[9]^2),
				(m[2]^2 + m[6]^2 + m[10]^2),
				(m[3]^2 + m[7]^2 + m[11]^2)
			) or 1
			
			self[3] = math.sqrt(3 * self[4].boundingBox.size^2 * scale)
		end
		return self[3]
	end,
	
	getObj = function(self)
		return self[4]
	end,
	
	setShaderID = function(self, sh)
		self[5] = sh
	end,
	
	getShaderID = function(self)
		return self[5]
	end,
	
	getBoneTransforms = function(self)
		return self[6]
	end,
	
	getDistance = function(self)
		return self[7]
	end,
	
	setDistance = function(self, d)
		self[7] = d
	end,
}