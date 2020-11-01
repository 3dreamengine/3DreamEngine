return {
	link = {"task"},
	
	getTransform = function(self)
		return self[1]
	end,
	
	getPos = function(self)
		if self[2] == false then
			local bb = self:getS().boundingBox
			local transform = self:getTransform()
			if bb then
				--mat4 * vec4(vec3, 1) multiplication, for performance reasons hardcoded
				local a = bb.center
				self[2] = vec3(transform[1] * a[1] + transform[2] * a[2] + transform[3] * a[3] + transform[4],
					transform[5] * a[1] + transform[6] * a[2] + transform[7] * a[3] + transform[8],
					transform[9] * a[1] + transform[10] * a[2] + transform[11] * a[3] + transform[12])
			else
				self[2] = vec3(transform[4], transform[8], transform[12])
			end
		end
		return self[2]
	end,
	
	getS = function(self)
		return self[3]
	end,
	
	getColor = function(self)
		return self[4]
	end,
	
	getObj = function(self)
		return self[5]
	end,
	
	getBoneTransforms = function(self)
		return self[6]
	end,
	
	getSize = function(self)
		local m = self[1]
		local scale = math.sqrt(
			math.max(
				(m[1]^2 + m[5]^2 + m[9]^2),
				(m[2]^2 + m[6]^2 + m[10]^2),
				(m[3]^2 + m[7]^2 + m[11]^2)
			)
		)
		return self[3].boundingBox.size * scale
	end,
}