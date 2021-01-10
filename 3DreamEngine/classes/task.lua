local identityMatrix = mat4:getIdentity()

return {
	link = {"task"},
	
	getTransform = function(self)
		return self[2] or identityMatrix
	end,
	
	getPos = function(self, subObj)
		if not self[3] then
			local bb = subObj.boundingBox
			local transform = self[2]
			if transform then
				--mat4 * vec4(vec3, 1) multiplication, for performance reasons hardcoded
				local a = bb.center
				self[3] = vec3(transform[1] * a[1] + transform[2] * a[2] + transform[3] * a[3] + transform[4],
					transform[5] * a[1] + transform[6] * a[2] + transform[7] * a[3] + transform[8],
					transform[9] * a[1] + transform[10] * a[2] + transform[11] * a[3] + transform[12])
			else
				self[3] = bb.center
			end
		end
		return self[3]
	end,
	
	getColor = function(self)
		return self[1]
	end,
	
	getSize = function(self, subObj)
		if not self[4] then
			local m = self[2]
			local scale = m and math.max(
				(m[1]^2 + m[5]^2 + m[9]^2),
				(m[2]^2 + m[6]^2 + m[10]^2),
				(m[3]^2 + m[7]^2 + m[11]^2)
			) or 1
			
			self[4] = math.sqrt(3 * subObj.boundingBox.size^2 * scale)
		end
		return self[4]
	end,
}