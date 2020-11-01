--[[
#part of the 3DreamEngine by Luke100000
loader.lua - loads objects
--]]

local lib = _3DreamEngine

local function newBoundaryBox()
	return {
		first = vec3(math.huge, math.huge, math.huge),
		second = vec3(-math.huge, -math.huge, -math.huge),
		center = vec3(0.0, 0.0, 0.0),
		size = 0
	}
end

local function removePostfix(t)
	local v = t:match("(.*)%.[^.]+")
	return v or t
end

local function clone(t)
	local n = { }
	for d,s in pairs(t) do
		n[d] = s
	end
	return n
end

--adapt the transform to the original object 
local function moveToMaster(obj, o)
	if obj.args.loadAsLibrary then
		local oo
		local search = removePostfix(o.name)
		for d,s in pairs(obj.objects) do
			if s.name == search and o ~= s then
				oo = s
				break
			end
		end
		if oo and oo.transform and o.transform then
			local t = oo.transform:invert() * o.transform
			o.transform = oo.transform
			
			--transform vertices
			for d,s in ipairs(o.vertices) do
				o.vertices[d] = {(t * vec3(s)):unpack()}
			end
			
			--transform normals
			local tn = t:subm()
			for d,s in ipairs(o.normals) do
				o.normals[d] = {(tn * vec3(s)):unpack()}
			end
		end
	end
end

--add to object library instead
function lib:loadLibrary(path, shaderType, args, prefix)
	if type(shaderType) == "table" then
		return self:loadLibrary(path, shaderType and shaderType.shaderType, shaderType)
	end
	args = args or { }
	args.shaderType = shaderType or args.shaderType
	
	prefix = prefix or ""
	
	args.no3doRequest = true
	args.loadAsLibrary = true
	
	--load
	local obj = self:loadObject(path, shaderType, args)
	
	--insert into library
	local overwritten = { }
	for name,o in pairs(obj.objects) do
		local id = prefix .. o.name
		if not overwritten[id] then
			overwritten[id] = true
			self.objectLibrary[id] = { }
		end
		
		table.insert(self.objectLibrary[id], o)
	end
	
	--insert collisions intro library
	local overwritten = { }
	if obj.collisions then
		for name,c in pairs(obj.collisions) do
			local id = removePostfix(prefix .. name)
			if not overwritten[id] then
				overwritten[id] = true
				self.collisionLibrary[id] = { }
			end
			
			table.insert(self.collisionLibrary[id], c)
		end
	end
end

--loads an object
--args is a table containing additional settings
--path is the absolute path without extension
--3do objects will be loaded part by part, threaded. yourObject.objects.yourMesh.mesh is nil, if its not loaded yet
function lib:loadObject(path, shaderType, args)
	if type(shaderType) == "table" then
		return self:loadObject(path, shaderType and shaderType.shaderType, shaderType)
	end
	args = args or { }
	args.shaderType = shaderType or args.shaderType
	
	--some shaderType specific settings
	if args.shaderType then
		local dat = self.shaderLibrary.base[args.shaderType]
		if args.splitMaterials == nil then
			args.splitMaterials = dat.splitMaterials
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
	
	local obj = self:newObject(path)
	
	obj.args = args
	
	--load files
	--if two object files are available (.obj and .vox) it might crash, since it loads all)
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
			
			--look for collision
			if typ == "obj" then
				if love.filesystem.getInfo(obj.path .. "_collision." .. typ) then
					self.loader[typ](self, obj, obj.path .. "_collision." .. typ, true)
				end
			end
			
			--skip furhter modifying and exporting if already packed as 3do
			--also skips mesh loading since it is done manually
			if typ == "3do" and not failed then
				break
			end
		end
		::skip::
	end
	
	if not found then
		error("object " .. obj.name .. " not found (" .. obj.path .. ")")
	end
	
	
	--remove empty objects
	for d,o in pairs(obj.objects) do
		if o.vertices and #o.vertices == 0 and not o.linked then
			obj.objects[d] = nil
		end
	end
	
	
	--extract positions
	for d,o in pairs(obj.objects) do
		if o.name:sub(1, 4) == "POS_" then
			--average position
			local x, y, z = 0, 0, 0
			for i,v in ipairs(o.vertices) do
				x = x + v[1]
				y = y + v[2]
				z = z + v[3]
			end
			local c = #o.vertices
			x = x / c
			y = y / c
			z = z / c
			
			--average size
			local r = 0
			for i,v in ipairs(o.vertices) do
				r = r + math.sqrt((v[1] - x)^2 + (v[2] - y)^2 + (v[3] - z)^2)
			end
			r = r / c
			
			--add position
			obj.positions[#obj.positions+1] = {
				name = removePostfix(o.name:sub(5)),
				size = r,
				x = x,
				y = y,
				z = z,
			}
			obj.objects[d] = nil
		end
	end
	
	
	--disable objects
	for d,o in pairs(obj.objects) do
		if o.name:sub(1, 9) == "DISABLED_" then
			o.disabled = true
		end
	end
	
	
	--detect links
	for d,o in pairs(obj.objects) do
		if o.name:sub(1, 5) == "LINK_" then
			local source = o.linked or removePostfix(o.name:sub(6))
			
			--remove original
			obj.objects[d] = nil
			
			--store link
			obj.linked = obj.linked or { }
			obj.linked[#obj.linked+1] = {
				source = source,
				transform = o.transform
			}
		end
	end
	
	
	--link objects
	if obj.linked then
		for id, link in ipairs(obj.linked) do
			local lo = self.objectLibrary[link.source]
			assert(lo, "linked object " .. link.source .. " is not in the object library!")
			
			--link
			for d,no in ipairs(lo) do
				local co = self:newLinkedObject(no)
				co.transform = link.transform
				co.linked = link.source
				obj.objects["link_" .. id .. "_" .. d .. "_" .. no.name] = co
			end
			
			--link collisions
			local lc = self.collisionLibrary[link.source]
			if lc then
				obj.collisions = obj.collisions or { }
				for d,no in ipairs(lc) do
					local co = clone(no)
					co.groupTransform = link.transform
					co.linked = link.source
					obj.collisions["link_" .. id .. "_" .. d .. "_" .. d] = co
				end
			end
		end
	end
	
	
	--LOD detection
	local groups = { }
	for d,o in pairs(obj.objects) do
		if o.name:sub(1, 4) == "LOD_" then
			local nr = tonumber(o.name:sub(5, 5))
			assert(nr, "LOD nr malformed: " .. o.name)
			
			o.name = o.name:sub(7)
			o.LODnr = nr
			groups[o.name] = math.max(groups[o.name] or 1, nr)
			
			moveToMaster(obj, o)
		end
	end
	
	--apply LOD level
	for d,o in pairs(obj.objects) do
		if groups[o.name] then
			local levels = groups[o.name]
			local nr = o.LODnr or 0
			
			---o:setLOD(nr / levels, nr < levels and (nr + 1) / levels)
		end
	end
	
	
	--shadow only detection
	local groups = { }
	for d,o in pairs(obj.objects) do
		if o.name:sub(1, 7) == "SHADOW_" then
			o.name = o.name:sub(8)
			o:setVisibility(false, true, false)
			moveToMaster(obj, o)
		end
	end
	
	
	--create particle systems
	if not obj.args.noParticleSystem then
		self:addParticlesystems(obj)
	end
	
	
	--remove empty objects (second pass)
	for d,s in pairs(obj.objects) do
		if s.vertices and #s.vertices == 0 then
			obj.objects[d] = nil
		end
	end
	
	
	--calculate bounding box
	if not obj.boundingBox then
		for d,s in pairs(obj.objects) do
			if not s.boundingBox then
				s.boundingBox = newBoundaryBox()
				
				--get aabb
				for i,v in ipairs(s.vertices) do
					local pos = vec3(v)
					s.boundingBox.first = s.boundingBox.first:min(pos)
					s.boundingBox.second = s.boundingBox.second:max(pos)
				end
				s.boundingBox.center = (s.boundingBox.second + s.boundingBox.first) / 2
				
				--get size
				local max = 0
				local c = s.boundingBox.center
				for i,v in ipairs(s.vertices) do
					local pos = vec3(v) - c
					max = math.max(max, pos:lengthSquared())
				end
				s.boundingBox.size = math.max(math.sqrt(max), s.boundingBox.size)
			end
		end
		
		--calculate total bounding box
		obj.boundingBox = newBoundaryBox()
		for d,s in pairs(obj.objects) do
			local sz = vec3(s.boundingBox.size, s.boundingBox.size, s.boundingBox.size)
			
			obj.boundingBox.first = s.boundingBox.first:min(obj.boundingBox.first - sz)
			obj.boundingBox.second = s.boundingBox.second:max(obj.boundingBox.second + sz)
			obj.boundingBox.center = (obj.boundingBox.second + obj.boundingBox.first) / 2
		end
		
		for d,s in pairs(obj.objects) do
			local o = s.boundingBox.center - obj.boundingBox.center
			obj.boundingBox.size = math.max(obj.boundingBox.size, s.boundingBox.size + o:lengthSquared())
		end
	end
	
	
	--extract collisions
	for d,o in pairs(obj.objects) do
		if o.name:sub(1, 10) == "COLLISION_" then
			if o.vertices then
				local id = o.name:sub(11)
				
				o.name = id
				moveToMaster(obj, o)
				
				--leave at origin for library entries
				if obj.args.loadAsLibrary then
					o.transform = nil
				end
				
				obj.collisions = obj.collisions or { }
				obj.collisionCount = (obj.collisionCount or 0) + 1
				obj.collisions[id] = self:getCollisionData(o)
			end
			obj.objects[d] = nil
		end
	end
	
	
	--post load materials
	for d,s in pairs(obj.materials) do
		s.dir = s.dir or obj.args.textures or obj.dir
		self:finishMaterial(s, obj)
	end
	
	
	--create meshes
	if not obj.args.noMesh then
		local cache = { }
		for d,o in pairs(obj.objects) do
			if not o.disabled and not o.linked then
				if cache[o.vertices] then
					o.mesh = cache[o.vertices].mesh
					o.tangents = cache[o.vertices].tangents
				else
					self:createMesh(o)
					cache[o.vertices] = o
				end
			end
		end
	end
	
	
	--cleaning up
	if obj.args.cleanup ~= false then
		for d,s in pairs(obj.objects) do
			if obj.args.cleanup then
				s.vertices = nil
				s.faces = nil
				s.edges = nil
			end
			
			s.normals = nil
			s.texCoords = nil
			s.colors = nil
			s.materials = nil
			s.extras = nil
			
			s.tangents = nil
		end
	end
	
	
	--3do exporter
	if obj.args.export3do then
		self:export3do(obj)
	end
	
	return obj
end

lib.meshTypeFormats = {
	textured = {
		{"VertexPosition", "float", 4},     -- x, y, z, extra
		{"VertexTexCoord", "float", 2},     -- UV
		{"VertexNormal", "byte", 4},        -- normal
		{"VertexTangent", "byte", 4},       -- normal tangent
	},
	textured_array = {
		{"VertexPosition", "float", 4},     -- x, y, z, extra
		{"VertexTexCoord", "float", 3},     -- UV
		{"VertexNormal", "byte", 4},        -- normal
		{"VertexTangent", "byte", 4},       -- normal tangent
	},
	simple = {
		{"VertexPosition", "float", 4},     -- x, y, z, extra
		{"VertexTexCoord", "float", 3},     -- normal
		{"VertexMaterial", "float", 3},     -- specular, glossiness, emissive
		{"VertexColor", "byte", 4},         -- color
	},
	material = {
		{"VertexPosition", "float", 4},     -- x, y, z, extra
		{"VertexTexCoord", "float", 3},     -- normal
		{"VertexMaterial", "float", 1},     -- material
	},
}

--takes an final and face table and generates the mesh and vertexMap
--note that .3do files has it's own mesh loader
function lib.createMesh(self, o)
	--set up vertex map
	local vertexMap = { }
	for d,f in ipairs(o.faces) do
		vertexMap[#vertexMap+1] = f[1]
		vertexMap[#vertexMap+1] = f[2]
		vertexMap[#vertexMap+1] = f[3]
	end
	
	--calculate vertex normals and uv normals
	local shader = self.shaderLibrary.base[o.shaderType]
	assert(shader, "shader '" .. tostring(o.shaderType) .. "' for object '" .. tostring(o.name) .. "' does not exist")
	if shader.requireTangents then
		self:calcTangents(o)
	end
	
	--create mesh
	local meshLayout = table.copy(self.meshTypeFormats[o.meshType])
	o.mesh = love.graphics.newMesh(meshLayout, #o.vertices, "triangles", "static")
	
	--vertex map
	o.mesh:setVertexMap(vertexMap)
	
	--set vertices
	local empty = {1, 0, 1, 1}
	for i = 1, #o.vertices do
		local vertex = o.vertices[i] or empty
		local normal = o.normals[i] or empty
		local texCoord = o.texCoords[i] or empty
		
		if o.meshType == "textured" then
			local tangent = o.tangents[i] or empty
			o.mesh:setVertex(i,
				vertex[1], vertex[2], vertex[3], o.extras[i] or 1,
				texCoord[1], texCoord[2],
				normal[1]*0.5+0.5, normal[2]*0.5+0.5, normal[3]*0.5+0.5, 0.0,
				tangent[1]*0.5+0.5, tangent[2]*0.5+0.5, tangent[3]*0.5+0.5, tangent[4] or 0.0
			)
		elseif o.meshType == "textured_array" then
			local tangent = o.tangents[i] or empty
			o.mesh:setVertex(i,
				vertex[1], vertex[2], vertex[3], o.extras[i] or 1,
				texCoord[1], texCoord[2], texCoord[3], 
				normal[1]*0.5+0.5, normal[2]*0.5+0.5, normal[3]*0.5+0.5, 0.0,
				tangent[1]*0.5+0.5, tangent[2]*0.5+0.5, tangent[3]*0.5+0.5, tangent[4] or 0.0
			)
		elseif o.meshType == "simple" then
			local material = o.materials[i] or empty
			local color = o.colors[i] or material.color or empty
			
			local specular = material.specular or material[1] or 0
			local glossiness = material.glossiness or material[2] or 0
			local emission = material.emission or material[3] or 0
			if type(emission) == "table" then
				emission = emission[1] / 3 + emission[2] / 3 + emission[3] / 3
			end
			
			o.mesh:setVertex(i,
				vertex[1], vertex[2], vertex[3], o.extras[i] or 1,
				normal[1], normal[2], normal[3],
				specular, glossiness, emission,
				color[1], color[2], color[3], color[4]
			)
		elseif o.meshType == "material" then
			o.mesh:setVertex(i,
				vertex[1], vertex[2], vertex[3], o.extras[i] or 1,
				normal[1], normal[2], normal[3],
				texCoord
			)
		end
	end
end