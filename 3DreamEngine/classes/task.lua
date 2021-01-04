local identityMatrix = mat4:getIdentity()

return {
	link = {"task"},
	
	getTransform = function(self)
		return self[5] or identityMatrix
	end,
	
	getPos = function(self)
		if not self[4] then
			local bb = self[1].boundingBox
			local transform = self[5]
			if transform then
				--mat4 * vec4(vec3, 1) multiplication, for performance reasons hardcoded
				local a = bb.center
				self[4] = vec3(transform[1] * a[1] + transform[2] * a[2] + transform[3] * a[3] + transform[4],
					transform[5] * a[1] + transform[6] * a[2] + transform[7] * a[3] + transform[8],
					transform[9] * a[1] + transform[10] * a[2] + transform[11] * a[3] + transform[12])
			else
				self[4] = bb.center
			end
		end
		return self[4]
	end,
	
	getS = function(self)
		return self[1]
	end,
	
	getColor = function(self)
		return self[2]
	end,
	
	getObj = function(self)
		return self[3]
	end,
	
	getScaledLOD = function(self)
		local LOD_min, LOD_max = self[1]:getScaledLOD()
		if LOD_min then
			return LOD_min, LOD_max
		else
			return self[3]:getScaledLOD()
		end
	end,
	
	getBoneTransforms = function(self)
		return self[7]
	end,
	
	getSize = function(self)
		if not self[6] then
			local m = self[5]
			local scale = math.max(
				(m[1]^2 + m[5]^2 + m[9]^2),
				(m[2]^2 + m[6]^2 + m[10]^2),
				(m[3]^2 + m[7]^2 + m[11]^2)
			)
			
			self[6] = math.sqrt(3 * self[1].boundingBox.size^2 * scale)
		end
		return self[6]
	end,
}