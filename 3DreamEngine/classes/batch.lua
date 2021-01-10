return {
	link = {"batch"},
	
	getTasks = function(self)
		return self[1]
	end,
	
	getSubObj = function(self)
		return self[2]
	end,
	
	getBoneTransforms = function(self)
		return self[6]
	end,
	
	isInstanced = function(self)
		return self[7]
	end,
}