local identityMatrix = mat4:getIdentity()

return {
	link = {"task"},
	
	getMesh = function(self)
		return self[1]
	end,
	
	getTransform = function(self)
		return self[2] or identityMatrix
	end,
	
	getPos = function(self)
		return self[3]
	end,
	
	getSize = function(self)
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