--[[
#part of the 3DreamEngine by Luke100000
loader.lua - loads objects
--]]

local lib = _3DreamEngine

local tags = {
	["PHYSICS"] = true,
	["LOD"] = true,
	["POS"] = true,
	["LINK"] = true,
	["BAKE"] = true,
	["SHADOW"] = true,
	["ID"] = true,
	["RAYTRACE"] = true,
	["REFLECTION"] = true,
	["REMOVE"] = true,
}

--buffers
local buffers = {
	"vertices",
	"normals",
	"texCoords",
	"colors",
	"materials",
	"extras",
	"weights",
	"joints",
}

lib.defaultArgs = {
	cleanup = true,
	mesh = true,
	export3do = false,
	skip3do = false,
	particlesystems = true,
	splitMaterials = false,
	meshType = "textured",
	flatten = false,
}

local function clone(t)
	local n = { }
	for d,s in pairs(t) do
		n[d] = s
	end
	return n
end

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

--add to object library instead
function lib:loadLibrary(path, args, prefix)
	args = prepareArgs(args)
	
	prefix = prefix or ""
	
	args.loadAsLibrary = true
	
	--load
	local obj = self:loadObject(path, args)
	
	--prepare lights for library entry
	for d,s in pairs(obj.lights) do
		local best = math.huge
		local g = obj.objects[s.name]
		if g and g.transform then
			--make the origin the center
			s.pos = g.transform:invert() * s.pos
		end
	end
	
	--insert into library
	local changed = { }
	for _,list in ipairs({"objects", "physics", "positions", "lights"}) do
		for _,o in pairs(obj[list] or { }) do
			local id = prefix .. o.name
			if not self.objectLibrary[id] then
				self.objectLibrary[id] = self:newObject()
			end
			if list == "physics" and not self.objectLibrary[id].physics then
				self.objectLibrary[id].physics = { }
			end
			changed[self.objectLibrary[id]] = true
			table.insert(self.objectLibrary[id][list], o)
			
			o.transform = nil
		end
	end
end

--remove objects without vertices
local function cleanEmpties(obj)
	for d,m in pairs(obj.meshes) do
		if m.vertices and #m.vertices == 0 and not m.linked or m.tags.remove then
			obj.meshes[d] = nil
		end
	end
end

local supportedFiles = {
	"mtl", --obj material file
	"mat", --3DreamEngine material file
	"3do", --3DreamEngine object file - way faster than obj but does not keep vertex information
	"vox", --magicka voxel
	"obj", --obj file
	"dae", --dae file
}

--loads an object
--path is the absolute path without extension
--args is a table containing additional settings
function lib:loadObject(path, args)
	--set default args
	args = prepareArgs(args)
	
	local obj = self:newObject(path)
	obj.args = args
	
	self.deltonLoad:start("load " .. obj.name)
	
	--load files
	local found = false
	for _,typ in ipairs(supportedFiles) do
		local info = love.filesystem.getInfo(obj.path .. "." .. typ)
		if info then
			--check if 3do is up to date
			if typ == "3do" then
				if args.skip3do then
					goto skip
				end
				
				local info2 = love.filesystem.getInfo(obj.path .. ".obj")
				if info2 and info2.modtime > info.modtime then
					goto skip
				end
				
				local info2 = love.filesystem.getInfo(obj.path .. ".dae")
				if info2 and info2.modtime > info.modtime then
					goto skip
				end
			end
			
			found = true
			
			--load object
			local failed = self.loader[typ](self, obj, obj.path .. "." .. typ)
			
			--skip furhter modifying and exporting if already packed as 3do
			--also skips mesh loading since it is done manually
			if typ == "3do" and not failed then
				goto skipWhen3do
				break
			end
		end
		::skip::
	end
	
	if not found then
		error("object " .. obj.name .. " not found (" .. obj.path .. ")")
	end
	
	
	--parse tags
	for _,m in pairs(obj.meshes) do
		m.tags = { }
		local possibles = string.split(m.name, "_")
		
		--in case the object consists of tags only, it is considered as a root object
		m.name = "root"
		
		for index,tag in ipairs(possibles) do
			local key, value = unpack(string.split(tag, ":"))
			if tags[key] then
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
	if not obj.args.flatten then
		for id,m in pairs(obj.meshes) do
			if m.name ~= "root" then
				local o = obj.objects[m.name]
				if not o then
					o = self:newObject(obj.path)
					o.name = m.name
					o.args = obj.args
					o.transform = m.transform
					m.transform = nil
					obj.objects[m.name] = o
				end
				
				obj.meshes[id] = nil
				o.meshes[id] = m
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
				objectName = m.name,
				name = type(m.tags.pos) == "string" and m.tags.pos or d,
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
	do
		local linkedNames = { }
		for d,o in pairs(obj.meshes) do
			if o.tags.link then
				--remove original
				obj.meshes[d] = nil
				
				--store link
				obj.linked = obj.linked or { }
				obj.linked[#obj.linked+1] = {
					source = o.linked or o.name,
					transform = o.transform
				}
			end
		end
	end
	
	
	--split materials
	do
		local changes = true
		while changes do
			changes = false
			for d,o in pairs(obj.meshes) do
				if obj.args.splitMaterials and not o.tags.bake and not o.tags.split then
					changes = true
					obj.meshes[d] = nil
					for i,m in ipairs(o.materials) do
						local d2 = d .. "_" .. m.name
						if not obj.meshes[d2] then
							local o2 = o:clone()
							o2.name = o.name .. "_" .. m.name
							o2.tags = table.copy(o.tags)
							o2.tags.split = true
							
							o2.material = m
							o2.translation = { }
							o2.faces = { }
							
							--clear buffers
							for _,buffer in ipairs(buffers) do
								if o2[buffer] then
									o2[buffer] = { }
								end
							end
							
							obj.meshes[d2] = o2
						end
						
						local o2 = obj.meshes[d2]
						local i2 = #o2.vertices+1
						
						--copy buffers
						o2.translation[i] = i2
						for _,buffer in ipairs(buffers) do
							if o2[buffer] then
								o2[buffer][i2] = o[buffer][i]
							end
						end
					end
					
					for i,f in ipairs(o.faces) do
						local m = o.materials[f[1]]
						local d2 = d .. "_" .. m.name
						local o2 = obj.meshes[d2]
						o2.faces[#o2.faces+1] = {
							o2.translation[f[1]],
							o2.translation[f[2]],
							o2.translation[f[3]],
						}
					end
				end
			end
			for d,o in pairs(obj.meshes) do
				o.translation = nil
			end
		end
	end
	
	
	--shadow only detection
	for d,o in pairs(obj.meshes) do
		if o.tags.shadow then
			if o.tags.shadow == "false" then
				o:setShadowVisibility(false)
			else
				o:setRenderVisibility(false)
				
				--hide rest of group in shadow pass
				for d2,o2 in pairs(obj.meshes) do
					if o2.name == o.name and not o.tags.shadow then
						o:setShadowVisibility(false)
					end
				end
			end
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
	if obj.linked then
		for id, link in ipairs(obj.linked) do
			local lo = self.objectLibrary[link.source]
			assert(lo, "linked object " .. link.source .. " is not in the object library!")
			
			--link
			for _,list in ipairs({"objects", "physics", "positions", "lights"}) do
				for d,no in ipairs(lo[list] or { }) do
					local co = list == "objects" and self:newLinkedObject(no) or no.clone and no:clone() or clone(no)
					
					if list == "lights" or list == "positions" then
						co.pos = link.transform * co.pos
					else
						co.transform = link.transform
					end
					
					co.linked = link.source
					co.name = "link_" .. id .. "_" .. co.name
					obj[list] = obj[list] or { }
					obj[list]["link_" .. id .. "_" .. d .. "_" .. no.name] = co
				end
			end
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
	
	
	--3do exporter
	if obj.args.export3do then
		--self:export3do(obj)
	end
end