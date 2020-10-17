--[[
#3do - 3Dream Object file (3DreamEngine specific)
blazing fast mesh loading using pre-calculated meshes and multi-threading
--]]

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
	
	obj.args.noParticleSystem = true
	obj.args.noMesh = true
	obj.args.export3do = false
	obj.args.centerMass = false
	obj.args.grid = false
	
	obj.DO_dataOffset = 12 + headerLength
	obj.DO_compressed = compressed
	obj.DO_path = path
	
	--recreate materials
	for d,s in pairs(obj.materials) do
		obj.materials[d] = table.merge(self:newMaterial(), s)
	end
	
	--recreate lights
	for d,s in pairs(obj.lights) do
		obj.lights[d] = table.merge(self:newLight(), s)
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
	if obj.collisions then
		for _,coll in pairs(obj.collisions) do
			for i,edge in ipairs(coll.edges) do
				edge[1] = vec3(edge[1])
				edge[2] = vec3(edge[2])
			end
			for i,face in ipairs(coll.faces) do
				face[1] = vec3(face[1])
				face[2] = vec3(face[2])
				face[3] = vec3(face[3])
			end
			for i,n in ipairs(coll.normals) do
				coll.normals[i] = vec3(n)
			end
			coll.point = vec3(coll.point)
			coll.transform = #coll.transform == 16 and mat4(coll.transform) or vec3(coll.transform)
		end
	end
	convert(obj.skeleton)
	
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
	
	if not obj.args.no3doRequest then
		obj:request()
	end
	file:close()
end