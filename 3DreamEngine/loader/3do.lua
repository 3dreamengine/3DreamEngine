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
	if typ ~= "3DO2" then
		print("3DO file " .. path .. " seems to be outdated and will be skipped")
		file:close()
		return true
	end
	
	local compressed = file:read(4):sub(1, 3)
	local l = file:read(4)
	local headerLength = love.data.unpack("J", l)
	local headerData = file:read(headerLength)
	
	local header = packTable.unpack(love.data.decompress("string", compressed, headerData))
	table.merge(obj, header)
	
	obj.args.particleSystems = false
	obj.args.mesh = false
	obj.args.export3do = false
	
	obj.DO_dataOffset = 12 + headerLength
	obj.DO_compressed = compressed
	obj.DO_path = path
	
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
		obj.objects[d] = table.merge(self:newSubObject(s.name, obj, s.material), s)
	end
	
	--relink materials
	for d,s in pairs(obj.objects) do
		local mat = self.materialLibrary[s.material] or obj.materials[s.material]
		if mat then
			s.material = mat
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
	
	--recreate collision data
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
	if obj.linked then
		for d,s in ipairs(obj.linked) do
			s.transform = mat4(s.transform)
		end
	end
	
	--cleanup
	for d,o in pairs(obj.objects) do
		if o.meshDataIndex then
			if #o.vertices == 0 then
				o.vertices = nil
			end
			o.loaded = false
			obj.loaded = false
		end
	end
	
	if obj.args.request3do then
		obj:request()
	end
	
	cache = { }
	file:close()
end