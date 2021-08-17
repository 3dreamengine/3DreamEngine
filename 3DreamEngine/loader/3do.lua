--[[
#3do - 3Dream Object file (3DreamEngine specific)
blazing fast mesh loading using pre-calculated meshes and multi-threading
--]]

--recursively recreates vectors
local function convert(t)
	if t then
		for d,s in pairs(t) do
			if type(s) == "table" then
				if type(s[1]) == "number" then
					if #s == 3 then
						t[d] = vec3(s)
					elseif #s == 3 then
						t[d] = vec4(s)
					elseif #s == 9 then
						t[d] = mat3(s)
					elseif #s == 16 then
						t[d] = mat4(s)
					else
						convert(s)
					end
				else
					convert(s)
				end
			end
		end
	end
end

return function(self, obj, path)
	--load header
	local file = love.filesystem.newFile(path, "r")
	local typ = file:read(4)
	
	--check if up to date
	if typ ~= "3DO4" then
		print("3DO file " .. path .. " seems to be outdated and will be skipped")
		file:close()
		return true
	end
	
	--unused 4 bytes
	local _ = file:read(4)
	
	--header
	local l = file:read(4)
	local headerLength = love.data.unpack("L", l)
	local headerData = file:read(headerLength)
	
	--object lua data
	local header = packTable.unpack(love.data.decompress("string", "lz4", headerData))
	table.merge(obj, header)
	
	--additional mesh data
	local meshData = { }
	if obj.meshData then
		for d,s in ipairs(obj.meshData) do
			meshData[d] = love.data.newByteData(love.data.decompress("string", "lz4", file:read(s)))
		end
	end
	obj.meshData = nil
	
	--mesh creation and 3DO exporting makes no longer sense
	obj.args.particleSystems = false
	obj.args.mesh = false
	obj.args.export3do = false
	
	--recreate materials
	for d,s in pairs(obj.materials) do
		obj.materials[d] = table.merge(self:newMaterial(), s)
	end
	
	--recreate lights
	for d,s in pairs(obj.lights) do
		local l = self:newLight()
		for d,s in pairs(s) do
			local m = type(l[d]) == "table" and getmetatable(l[d])
			if m then
				l[d] = setmetatable(s, m)
			else
				l[d] = s
			end
		end
		obj.lights[d] = l
	end
	
	--recreate objects
	for d,s in pairs(obj.objects) do
		obj.objects[d] = table.merge(self:newObject(s.name, obj, s.material), s)
	end
	
	--recreate meshes
	print("todo, requires recursive 3do fix")
	for _,o in pairs(obj.meshes) do
		for d,s in pairs(o) do
			if type(s) == "table" and type(s.vertices) == "number" then
				s.vertexMap = s.vertexMap and meshData[s.vertexMap]
				s.vertices = meshData[s.vertices]
			end
		end
	end
	
	--relink materials
	for d,s in pairs(obj.objects) do
		local mat = type(s.material) == "table" and s.material or self.materialLibrary[s.material] or obj.materials[s.material]
		if mat then
			s.material = setmetatable(mat, self.meta.material)
		else
			file:close()
			error("material " .. tostring(s.material) .. " required by object " .. tostring(obj.name) .. " does not exist!")
		end
	end
	
	--recreate vecs and mats
	convert(obj.boundingBox)
	for d,o in pairs(obj.objects) do
		convert(o.boundingBox)
		if o.transform then
			o.transform = mat4(o.transform)
		end
	end
	
	--reflections
	if obj.reflections then
		for _,reflection in ipairs(obj.reflections) do
			reflection.pos = vec3(reflection.pos)
			reflection.first = vec3(reflection.first)
			reflection.second = vec3(reflection.second)
		end
	end
	
	--recreate skeleton data
	convert(obj.skeleton)
	
	--recreate animation data
	if obj.animations then
		for _,anim in pairs(obj.animations) do
			for _,part in pairs(anim) do
				for _,frame in ipairs(part) do
					frame.position = vec3(frame.position)
					frame.rotation = quat(frame.rotation)
				end
			end
		end
	end
	
	--recreate physics data
	if obj.physics then
		for _,coll in pairs(obj.physics) do
			coll.transform = mat4(coll.transform)
			convert(coll.vertices)
			convert(coll.normals)
		end
	end
	
	--recreate linked data
	if obj.linkedObjects then
		for d,s in ipairs(obj.linkedObjects) do
			s.transform = mat4(s.transform)
		end
	end
	
	cache = { }
	file:close()
end