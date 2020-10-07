local lib = _3DreamEngine

function lib:newObject(path)
	--get name and dir
	local n = self:split(path, "/")
	local name = n[#n] or path
	local dir = #n > 1 and table.concat(n, "/", 1, #n-1) or ""
	
	return setmetatable({
		materials = {
			None = self:newMaterial()
		},
		objects = { },
		positions = { },
		lights = { },
		args = { },
		
		path = path, --absolute path to object
		name = name, --name of object
		dir = dir, --dir containing the object
		
		--the object transformation
		transform = mat4:getIdentity(),
	}, self.meta.object)
end

return {
	link = {"clone", "transform", "shader", "visibility"},
}