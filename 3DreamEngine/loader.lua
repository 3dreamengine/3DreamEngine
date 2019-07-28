--[[
#part of the 3DreamEngine by Luke100000
#see init.lua for license and documentation
loader.lua - loads objects
--]]

local lib = _3DreamEngine

--master resource loader
lib.resourceLoader = {jobs = { }, self = lib}
function lib.resourceLoader.add(self, object, priority)
	self.jobs[#self.jobs+1] = {object = object, priority = priority or 3}
end

--updates active resource tasks (mesh loading, texture loading, ...)
function lib.resourceLoader.update(self, time)
	
end

--loads an opject
--args is a table containing additional instructions on how to load the object (more informations in the local obj = { } creation)
--path is either absolute (starting from the games root dir) or relative (starting from the optional set project objects base dir)
--if not disabled with args.noLazy, 3do objects will be loaded part by part. If abstracted files are available (yourObject_simple_1.3do) it will load the simplest file first and only load more detailed object once actually needed. Yourobject.objects.yourObject.loaded shows you if a mesh is fully loaded, .mesh might be a simplified version too, if present.
function lib.loadObject(self, path, args)
	if args and type(args) ~= "table" then
		error("arguments are now packed in a table, check init.lua for example")
	end
	args = args or { }
	
	local supportedFiles = {
		"mtl", --obj material file
		"vox", --magicka voxel
		"3de", --3DreamEngine information file
		"obj", --obj file
		"3do", --3DreamEngine object file - way faster than obj but does not keep vertex information
	}
	
	--make absolute
	for _,typ in ipairs(supportedFiles) do
		if love.filesystem.getInfo(self.objectDir .. "/" .. path .. "." .. typ) then
			path = self.objectDir .. "/" .. path
			break
		end
	end
	
	--get name and dir
	local n = self:split(path, "/")
	name = n[#n] or path
	local dir = #n > 1 and table.concat(n, "/", 1, #n-1) or ""
	
	local obj = {
		materials = {None = {color = {1.0, 1.0, 1.0, 1.0}, specular = 0.5, name = "None", ID = 1}},
		materialsID = {"None"},
		objects = { },
		
		--instead of loading LIGHT_ objects as meshes, put them into the lights table for manual use and skip them.
		lights = { },
		
		path = path, --absolute path to object
		name = name, --name of object
		dir = dir, --dir containing the object
		
		--args
		splitMaterials = args.splitMaterials,            -- if a single mesh has different textured materials, it has to be split into single meshes. splitMaterials does this automatically.
		raster = args.raster,                            -- load the object as 3D raster of different meshes (must be split). Instead of an 1D table, obj.objects[x][y][z] will be created.
		forceTextured = args.forceTextured,              -- if the mesh gets created, it will determine texture mode or simple mode based on tetxures. forceTextured always loads as (non set) texture.
		noMesh = args.noMesh,                            -- load vertex information but do not create a final mesh - template objects etc
		noParticleSystem = args.noParticleSystem == nil and args.noMesh or args.noParticleSystem, -- prevent the particle system from bein generated, used by template objects, ... If noMesh is true and noParticleSystem nil, it assume noParticleSystem should be true too.
		cleanup = (args.cleanup == nil or args.cleanup), -- release vertex, ... information once done - prefer using 3do files if cleanup is nil or true, since then it would not even load this information into RAM
		noLazy = args.noLazy,                            -- prevent .3do from bein loaded lazy
		
		--the object transformation
		transform = matrix{
			{1, 0, 0, 0},
			{0, 1, 0, 0},
			{0, 0, 1, 0},
			{0, 0, 0, 1},
		},
		
		--project related functions
		reset = self.reset,
		translate = self.translate,
		scale = self.scale,
		rotateX = self.rotateX,
		rotateY = self.rotateY,
		rotateZ = self.rotateZ,
		
		self = self,
	}
	
	obj.loaded = false
	
	--register textures relative to the project
	self.textures:add(obj.dir, true)
	
	--load files
	--if two object files are available (.obj and .vox) it might crash, since it loads all)
	local found = false
	for _,typ in ipairs(supportedFiles) do
		if love.filesystem.getInfo(obj.path .. "." .. typ) then
			found = true
			
			--load the simplified objects if existing
			for i = 8, 1, -1 do
				if love.filesystem.getInfo(obj.path .. "_simple_" .. i .. "." .. typ) then
					--load object and insert it to current
					self.loader[typ](self, obj, obj.path .. "_simple_" .. i .. "." .. typ, i)
				end
			end
			
			--load most detailed/default object
			self.loader[typ](self, obj, obj.path .. "." .. typ)
			for d,s in pairs(obj.objects) do
				if not s.simpler and obj.objects[d .. "_simple_1"] then
					s.simpler = d .. "_simple_1"
				end
			end
		end
	end
	if not found then
		error("object " .. obj.name .. " not found (" .. obj.path .. ")")
	end
	
	
	--extract light sources
	for d,s in pairs(obj.objects) do
		pos = s.name:find("LAMP")
		if pos then
			local x, y, z = 0, 0, 0
			for i,v in ipairs(s.final) do
				x = x + v[1]
				y = y + v[2]
				z = z + v[3]
			end
			x = x / #s.final
			y = y / #s.final
			z = z / #s.final
			obj.lights[#obj.lights+1] = {
				name = s.name:sub(pos+5),
				x = x,
				y = y,
				z = z,
			}
			obj.objects[d] = nil
		end
	end
	
	
	--link textures to materials
	for d,s in pairs(obj.materials) do
		for _,t in ipairs({"diffuse", "normal", "specular"}) do
			local custom = s["tex_" .. t]
			s["tex_" .. t] = nil
			for _,p in ipairs({
				custom and (obj.dir .. "/" .. custom) or false,    -- custom name, relative to object file
				custom or false,                                   -- custom name, relative to root
				obj.dir .. "/" .. d .. "_" .. t,                   -- same name as material, relative to object file
				d .. "_" .. t,                                     -- same name as material, relative to root
				obj.dir .. "/" .. obj.name .. "_" .. t,            -- same name as object name, relative to object file
				obj.name .. "_" .. t,                              -- same name as object name, relative to root
			}) do
				if p and self.textures:get(p) then
					s["tex_" .. t] = p
					break
				end
			end
			
			--failed to load custom image set in mtl
			if custom and not s["tex_" .. t] then
				error("can not find texture specified in the .mtl file: " .. tostring(custom))
			end
		end
	end
	
	
	--if raster is enabled, calculate their position in the grid and move it to the center. The 'position' is the ceiled integer vertex weight origin.
	if obj.raster then
		for d,o in pairs(obj.objects) do
			local x, y, z = 0, 0, 0
			for i,v in ipairs(o.final) do
				x = x + v[1]
				y = y + v[2]
				z = z + v[3]
			end
			o.x = math.ceil(x / #o.final)
			o.y = math.ceil(y / #o.final)
			o.z = math.ceil(z / #o.final)
			
			for i,v in ipairs(o.final) do
				v[1] = v[1] - o.x
				v[2] = v[2] - o.y
				v[3] = v[3] - o.z
			end
		end
	end
	
	
	--create particle systems
	self:addParticlesystems(obj)
	
	
	--remove empty objects
	for d,s in pairs(obj.objects) do
		if s.final and #s.final == 0 then
			obj.objects[d] = nil
		end
	end
	
	
	--create meshes
	if not obj.noMesh then
		for d,o in pairs(obj.objects) do
			if not o.finished then
				o.finished = true
				self:createMesh(obj, o)
			end
		end
	end
	
	
	--cleaning up
	if obj.cleanup then
		for d,s in pairs(obj.objects) do
			s.faces = nil
			s.final = nil
		end
		collectgarbage()
	end
	
	
	--if raster is enabled, rename the objects to a 3 dim array based on the position calculated before
	if obj.raster then
		local objects = obj.objects
		obj.objects = { }
		for d,o in pairs(objects) do
			obj.objects[o.x] = obj.objects[o.x] or { }
			obj.objects[o.x][o.y] = obj.objects[o.x][o.y] or { }
			if obj.objects[o.x][o.y][o.z] then
				print("object atlas intersection at " .. o.x .. "*" .. o.y .. "*" .. o.z .. ": " .. d)
			end
			obj.objects[o.x][o.y][o.z] = o
		end
	end
	
	return obj
end

--takes an final and face table (inside .obj) and generates the mesh and vertexMap
--note that .3do files has it's own mesh loader
function lib.createMesh(self, obj, o)
	--backup material
	if not o.material then
		o.material = {color = {1.0, 1.0, 1.0, 1.0}, specular = 0.5, name = "None"}
	end
	
	--mesh structure
	local atypes
	local textureMode
	if o.material.tex_diffuse or obj.forceTextured then
		textureMode = true
		atypes = {
		  {"VertexPosition", "float", 4},	-- x, y, z
		  {"VertexTexCoord", "float", 2},	-- UV
		  {"VertexNormal", "float", 3},		-- normal
		  {"VertexTangent", "float", 3},	-- normal tangent
		  {"VertexBitangent", "float", 3},	-- normal bitangent
		}
	else
		textureMode = false
		atypes = {
		  {"VertexPosition", "float", 4},	-- x, y, z
		  {"VertexTexCoord", "float", 4},	-- normal, specular
		  {"VertexColor", "byte", 4},		-- color
		}
	end
	
	--remove unused finals and set up vertex map
	local vertexMap = { }
	local finals = { }
	local finalsIDs = { }
	for d,f in ipairs(o.faces) do
		for i = 1, 3 do
			if not finalsIDs[f[i]] then
				finals[#finals+1] = o.final[f[i]]
				finalsIDs[f[i]] = #finals
			end
			vertexMap[#vertexMap+1] = finalsIDs[f[i]]
		end
	end
	
	--calculate vertex normals and uv normals
	if textureMode then
		for f = 1, #vertexMap, 3 do
			local P1 = finals[vertexMap[f+0]]
			local P2 = finals[vertexMap[f+1]]
			local P3 = finals[vertexMap[f+2]]
			local N1 = finals[vertexMap[f+0]]
			local N2 = finals[vertexMap[f+1]]
			local N3 = finals[vertexMap[f+2]]
			
			local tangent = { }
			local bitangent = { }
			
			local edge1 = {P2[1] - P1[1], P2[2] - P1[2], P2[3] - P1[3]}
			local edge2 = {P3[1] - P1[1], P3[2] - P1[2], P3[3] - P1[3]}
			local edge1uv = {N2[9] - N1[9], N2[10] - N1[10]}
			local edge2uv = {N3[9] - N1[9], N3[10] - N1[10]}
			
			local cp = edge1uv[2] * edge2uv[1] - edge1uv[1] * edge2uv[2]
			
			if cp ~= 0.0 then
				for i = 1, 3 do
					tangent[i] = (edge1[i] * edge2uv[2] - edge2[i] * edge1uv[2]) / cp
					bitangent[i] = (edge2[i] * edge1uv[1] - edge1[i] * edge2uv[1]) / cp
				end
				
				local l = math.sqrt(tangent[1]^2+tangent[2]^2+tangent[3]^2)
				tangent[1] = tangent[1] / l
				tangent[2] = tangent[2] / l
				tangent[3] = tangent[3] / l
				
				local l = math.sqrt(bitangent[1]^2+bitangent[2]^2+bitangent[3]^2)
				bitangent[1] = bitangent[1] / l
				bitangent[2] = bitangent[2] / l
				bitangent[3] = bitangent[3] / l
				
				for i = 1, 3 do
					finals[vertexMap[f+i-1]][11] = (finals[vertexMap[f+i-1]][11] or 0) + tangent[1]
					finals[vertexMap[f+i-1]][12] = (finals[vertexMap[f+i-1]][12] or 0) + tangent[2]
					finals[vertexMap[f+i-1]][13] = (finals[vertexMap[f+i-1]][13] or 0) + tangent[3]
					
					finals[vertexMap[f+i-1]][14] = (finals[vertexMap[f+i-1]][14] or 0) + bitangent[1]
					finals[vertexMap[f+i-1]][15] = (finals[vertexMap[f+i-1]][15] or 0) + bitangent[2]
					finals[vertexMap[f+i-1]][16] = (finals[vertexMap[f+i-1]][16] or 0) + bitangent[3]
				end
			end
		end
		
		--complete smoothing step
		for d,f in ipairs(finals) do
			if f[11] then
				--Gram-Schmidt orthogonalization
				local dot = (f[11] * f[5] + f[12] * f[6] + f[13] * f[7])
				f[11] = f[11] - f[5] * dot
				f[12] = f[12] - f[6] * dot
				f[13] = f[13] - f[7] * dot
				
				local l = math.sqrt(f[11]^2+f[12]^2+f[13]^2)
				f[11] = -f[11] / l
				f[12] = -f[12] / l
				f[13] = -f[13] / l
				
				l = math.sqrt(f[14]^2+f[15]^2+f[16]^2)
				f[14] = f[14] / l
				f[15] = f[15] / l
				f[16] = f[16] / l
			end
		end
	end
	
	--here would be the .3do exporter
	
	--create mesh
	o.mesh = love.graphics.newMesh(atypes, #finals, "triangles", "static")
	
	--vertex map
	o.mesh:setVertexMap(vertexMap)
	
	for d,s in ipairs(finals) do
		local m = o.materialsID and o.materialsID[s[8]] or  obj.materialsID[s[8]]
		local c = m.color
		if textureMode then
			o.mesh:setVertex(d,
				s[1], s[2], s[3], s[4],
				s[9], s[10],
				s[5], s[6], s[7],
				s[11], s[12], s[13],
				s[14], s[15], s[16]
			)
		else
			o.mesh:setVertex(d,
				s[1], s[2], s[3], s[4],
				s[5], s[6], s[7],
				m.specular,
				c[1], c[2], c[3], c[4]
			)
		end
	end
	
	o.mesh:flush()
	o.loaded = true
end