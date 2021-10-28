--[[
#part of the 3DreamEngine by Luke100000
loader.lua - loads objects
--]]

local lib = _3DreamEngine

--tags that will get recognized
lib.meshTags = {
	["PHYSICS"] = true,
	["LOD"] = true,
	["POS"] = true,
	["LINK"] = true,
	["BAKE"] = true,
	["ID"] = true,
	["RAYTRACE"] = true,
	["REFLECTION"] = true,
	["REMOVE"] = true,
	["SHADOW"] = true,
}

--the default args used by the object loader
lib.defaultArgs = {
	cleanup = true,
	mesh = true,
	export3do = false,
	skip3do = false,
	particlesystems = true,
	meshType = "textured",
	scene = false,
}

--extends given arg table with default args
local function prepareArgs(args)
	if type(args) == "string" then
		error("loadObjects signature has changed, please check docu")
	end
	
	args = table.copy(args or { })
	
	for d,s in pairs(lib.defaultArgs) do
		if args[d] == nil then
			args[d] = s
		end
	end
	
	return args
end

--remove objects without vertices
local function cleanEmpties(obj)
	for d,m in pairs(obj.meshes) do
		if m.vertices and #m.vertices == 0 or m.tags.remove then
			obj.meshes[d] = nil
		end
	end
end

lib.supportedFiles = {
	"mtl", --obj material file
	"mat", --3DreamEngine material file
	"3do", --3DreamEngine object file - way faster than obj but does not keep vertex information
	"vox", --magicka voxel
	"obj", --obj file
	"dae", --dae file
}

--add to object library instead
function lib:loadLibrary(path, args, prefix)
	args = prepareArgs(args)
	args.loadAsLibrary = true
	
	--load
	local obj = self:loadObject(path, args)
	
	--insert into library
	local changed = { }
	for d,o in pairs(obj.objects) do
		local id = (prefix or "") .. d
		self.objectLibrary[id] = o
	end
end

--loads an scene
--this is just a wrapper for loadObject with the scene flag enabled
function lib:loadScene(path, args)
	args = args and table.copy(args) or { }
	args.scene = true
	return self:loadObject(path, args)
end

--loads an object
--path is the absolute path without extension
--args is a table containing additional settings
function lib:loadObject(path, args)
	--set default args
	args = prepareArgs(args)
	
	local obj = self:newObject(path)
	obj.args = args
	
	self.deltonLoad:start("load " .. obj.name)
	
	--test for existing files
	local found = { }
	local newest = 0
	for _,typ in ipairs(lib.supportedFiles) do
		local info = love.filesystem.getInfo(obj.path .. "." .. typ)
		if info then
			found[typ] = info.modtime or 0
			newest = math.max(info.modtime or 0, newest)
		end
	end
	
	--skip old 3do files
	if args.skip3do or found["3do"] and found["3do"] < newest then
		found["3do"] = nil
	end
	
	--load files
	for _,typ in ipairs(lib.supportedFiles) do
		if found[typ] then
			--load object
			local failed = self.loader[typ](self, obj, obj.path .. "." .. typ)
			
			--skip furhter modifying and exporting if already packed as 3do
			--also skips mesh loading since it is done manually
			if typ == "3do" and not failed then
				goto skipWhen3do
				break
			end
		end
	end
	
	if not found then
		error("object " .. obj.name .. " not found (" .. obj.path .. ")")
	end
	
	
	--parse tags
	for nnn,m in pairs(obj.meshes) do
		m.tags = { }
		local possibles = string.split(m.name, "_")
		
		--in case the object consists of tags only, it is considered as a root object
		m.name = "root"
		
		for index,tag in ipairs(possibles) do
			local key, value = unpack(string.split(tag, ":"))
			if lib.meshTags[key] then
				--tag found
				m.tags[key:lower()] = value or true
			else
				--cancel, the rest is the name
				if key:upper() == key and key:lower() ~= key then
					print(string.format("unknown tag '%s' of object '%s' in '%s'", key, m.name, path))
				end
				m.name = table.concat(possibles, "_", index)
				break
			end
		end
	end
	
	
	--remove empty meshes
	cleanEmpties(obj)
	
	
	--restructure into tree, the root node contains no data
	if obj.args.scene then
		for id,m in pairs(obj.meshes) do
			if not m.tags.link and not m.tags.reflection then
				local o = obj.objects[m.name]
				if not o then
					o = self:newObject(obj.path)
					o.name = m.name
					o.args = obj.args
					o.transform = m.transform
					m.transform = nil
					obj.objects[m.name] = o
				else
					--make sure to transform accordingly
					if m.transform ~= o.transform then
						local transform = o.transform:invert() * m.transform
						print("todo: two objects with the same name have different transform matrices, that is illegal!")
					end
					
					m.transform = nil
				end
				
				obj.meshes[id] = nil
				o.meshes[id] = m
			end
		end
		
		--same for light
		for id,m in pairs(obj.lights) do
			if m.name ~= "root" then
				local o = obj.objects[m.name]
				if o then
					--make sure to transform accordingly
					m.pos = o.transform:invert() * m.pos
					
					obj.lights[id] = nil
					o.lights[id] = m
				end
				
			end
		end
	end
	
	
	--extract positions, physics, ...
	for _,o in pairs(obj.objects) do
		self:processObject(o)
	end
	self:processObject(obj)
	
	
	::skipWhen3do::
	
	
	--create meshes, link library entries, ...
	for _,o in pairs(obj.objects) do
		self:finishObject(o)
	end
	self:finishObject(obj)
	
	
	--3do exporter
	if obj.args.export3do then
		self:export3do(obj)
	end
	
	
	self.deltonLoad:stop()
	return obj
end

function lib:processObject(obj)
	--extract positions
	for d,m in pairs(obj.meshes) do
		if m.tags.pos then
			--average position
			local x, y, z = 0, 0, 0
			for i,v in ipairs(m.vertices) do
				x = x + v[1]
				y = y + v[2]
				z = z + v[3]
			end
			local c = #m.vertices
			x = x / c
			y = y / c
			z = z / c
			
			--average size
			local r = 0
			for i,v in ipairs(m.vertices) do
				r = r + math.sqrt((v[1] - x)^2 + (v[2] - y)^2 + (v[3] - z)^2)
			end
			r = r / c
			
			if m.transform then
				x, y, z = (m.transform * vec3(x, y, z)):unpack()
			end
			
			--add position
			table.insert(obj.positions, {
				name = type(m.tags.pos) == "string" and m.tags.pos or m.name,
				size = r,
				x = x,
				y = y,
				z = z,
			})
			obj.meshes[d] = nil
		end
	end
	
	
	--extract reflections
	for d,o in pairs(obj.meshes) do
		if o.tags.reflection then
			--average position
			local h = math.huge
			local min = vec3(h, h, h)
			local max = vec3(-h, -h, -h)
			for i,v in ipairs(o.vertices) do
				min = min:min(vec3(v))
				max = max:max(vec3(v))
			end
			
			--new reflection object
			local r = self:newReflection(self.textures.sky_fallback)
			r.ID = d
			
			if o.transform then
				min = o.transform * min
				max = o.transform * max
				r.first = min:min(max)
				r.second = max:max(min)
				r.pos = vec3(o.transform[4], o.transform[8], o.transform[12])
			else
				r.first = min
				r.second = max
				r.pos = (r.first + r.second) / 2
			end
			
			--remove as object
			table.insert(obj.reflections, r)
			obj.meshes[d] = nil
		end
	end
	
	
	--detect links
	for d,o in pairs(obj.meshes) do
		if o.tags.link then
			--remove original
			obj.meshes[d] = nil
			
			--store link
			obj.linkedObjects = obj.linkedObjects or { }
			table.insert(obj.linkedObjects, {
				source = o.name,
				transform = o.transform
			})
		end
	end
	
	
	--LOD detection
	for _,typ in ipairs({"renderVisibility", "shadowVisibility"}) do
		local max = { }
		for d,o in pairs(obj.meshes) do
			if o[typ] ~= false and o.tags.lod then
				local nr = tonumber(o.tags.lod)
				assert(nr, "LOD nr malformed: " .. o.name .. " (use 'LOD:integer')")
				max[o.name] = math.max(max[o.name] or 0, nr)
			end
		end
		
		--apply LOD level
		for d,o in pairs(obj.meshes) do
			if o[typ] ~= false and max[o.name] then
				local nr = tonumber(o.tags.lod) or 0
				o:setLOD(nr, max[o.name] == nr and math.huge or nr+1)
			end
		end
	end
	
	
	--raytrace objects are usually not meant to be rendered
	for d,o in pairs(obj.meshes) do
		if o.tags.raytrace then
			o:setVisible(false)
		end
	end
	
	
	--raytrace objects are usually not meant to be rendered
	for d,o in pairs(obj.meshes) do
		if o.tags.shadow == "false" then
			o:setShadowVisibility(false)
		elseif o.tags.shadow then
			o:setRenderVisibility(false)
		end
	end
	
	
	--extract physics
	for d,o in pairs(obj.meshes) do
		if o.tags.physics then
			if o.vertices then
				--leave at origin for library entries
				if obj.args.loadAsLibrary then
					o.transform = nil
				end
				
				--2.5D physics
				if o.tags.physics then
					obj.physics = obj.physics or { }
					obj.physics[d] = self:getPhysicsData(o)
				end
			end
			
			--remove if no longer used
			if not o.tags.lod and not o.tags.bake then
				obj.meshes[d] = nil
			end
		end
	end
	
	
	--create particle systems
	if obj.args.particlesystems then
		self:addParticlesystems(obj)
	end
	
	
	--remove empty objects (second pass)
	cleanEmpties(obj)
	
	
	--calculate bounding box
	if not obj.boundingBox.initialized then
		obj:updateBoundingBox()
	end
	
	
	--post load materials
	do
		local done = { }
		for d,s in pairs(obj.materials) do
			s.dir = s.dir or obj.args.textures or obj.dir
			self:finishMaterial(s, obj)
			done[s] = true
		end
		for d,s in pairs(obj.meshes) do
			if not done[s] then
				done[s]  = true
				self:finishMaterial(s.material, obj)
			end
		end
	end
	
	
	--bake
	do
		local groups = { }
		for d,o in pairs(obj.meshes) do
			if o.tags.bake then
				if not groups[o.tags.bake] then
					groups[o.tags.bake] = {o}
				else
					table.insert(groups[o.tags.bake], o)
				end
			end
		end
		for d,s in pairs(groups) do
			self:bakeMaterials(s, obj.path .. "_" .. tostring(d))
		end
	end
end

function lib:finishObject(obj)	
	--link objects
	if obj.linkedObjects then
		for id, link in ipairs(obj.linkedObjects) do
			local lo = self.objectLibrary[link.source]
			assert(lo, "linked object " .. link.source .. " is not in the object library!")
			local o = self:newLinkedObject(lo, link.source)
			o.transform = link.transform
			obj.objects["link_" .. id] = o
		end
	end
	
	
	--create meshes
	if obj.args.mesh then
		self:createMesh(obj)
	end
	
	
	--callback
	if obj.args.callback then
		obj.args.callback(obj)
	end
	
	
	--init modules
	obj:initShaders()
	
	
	--cleaning up
	if obj.args.cleanup then
		obj:cleanup()
	end
end