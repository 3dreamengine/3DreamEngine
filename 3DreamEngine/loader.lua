--[[
#part of the 3DreamEngine by Luke100000
loader.lua - loads objects
--]]

local lib = _3DreamEngine

local function newBoundaryBox()
	return {
		first = vec3(math.huge, math.huge, math.huge),
		second = vec3(-math.huge, -math.huge, -math.huge),
		dimensions = vec3(0.0, 0.0, 0.0),
		center = vec3(0.0, 0.0, 0.0),
		size = 0
	}
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
	
	local supportedFiles = {
		"mtl", --obj material file
		"mat", --3DreamEngine material file
		"3do", --3DreamEngine object file - way faster than obj but does not keep vertex information
		"vox", --magicka voxel
		"obj", --obj file
		"dae", --dae file
	}
	
	local obj = self:newObject(path)
	
	--merge args
	for d,s in pairs(args) do
		obj[d] = obj[d] or s
	end
	
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
				obj.noParticleSystem = true
				obj.noMesh = true
				obj.export3do = false
				obj.centerMass = false
				obj.grid = false
				break
			end
		end
		::skip::
	end
	
	if not found then
		error("object " .. obj.name .. " not found (" .. obj.path .. ")")
	end
	
	
	--extract positions
	for d,s in pairs(obj.objects) do
		local pos = s.name:find("POS_")
		if pos then
			local x, y, z = 0, 0, 0
			for i,v in ipairs(s.vertices) do
				x = x + v[1]
				y = y + v[2]
				z = z + v[3]
			end
			local c = #s.vertices
			x = x / c
			y = y / c
			z = z / c
			
			local r = 0
			for i,v in ipairs(s.vertices) do
				r = r + math.sqrt((v[1] - x)^2 + (v[2] - y)^2 + (v[3] - z)^2)
			end
			r = r / c
			
			local stop = s.name:find(".", pos, true)
			obj.positions[#obj.positions+1] = {
				name = s.name:sub(pos+4, stop and (stop - 1) or #s.name),
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
		local pos = o.name:find("DISABLED")
		if pos then
			o.disabled = true
		end
	end
	
	--grid moves all vertices in a way that 0, 0, 0 is the floored origin with an maximal overhang of 0.25 units.
	if obj.grid then
		for d,o in pairs(obj.objects) do
			local minX, minY, minZ
			for i,v in ipairs(o.vertices) do
				minX = math.min(minX or v[1], v[1])
				minY = math.min(minY or v[2], v[2])
				minZ = math.min(minZ or v[3], v[3])
			end
			
			o.x = math.floor((minX or 0) + 0.25)
			o.y = math.floor((minY or 0) + 0.25)
			o.z = math.floor((minZ or 0) + 0.25)
			
			for i,v in ipairs(o.vertices) do
				v[1] = v[1] - o.x
				v[2] = v[2] - o.y
				v[3] = v[3] - o.z
			end
		end
	end
	
	--move object to its center of vertice mass
	if obj.centerMass then
		for d,o in pairs(obj.objects) do
			if not (d:sub(1, 10) == "COLLISION_" and obj.objects[d:sub(11)]) then
				local x, y, z = 0, 0, 0
				for i,v in ipairs(o.vertices) do
					x = x + v[1]
					y = y + v[2]
					z = z + v[3]
				end
				
				local c = #o.vertices
				o.cx = x / c
				o.cy = y / c
				o.cz = z / c
				
				for i,v in ipairs(o.vertices) do
					o.vertices[i] = {v[1] - o.cx, v[2] - o.cy, v[3] - o.cz}
				end
			end
		end
	end
	
	--use mass center of collisions actual mesh
	if obj.centerMass then
		for d,o in pairs(obj.objects) do
			if d:sub(1, 10) == "COLLISION_" and obj.objects[d:sub(11)] then
				local o2 = obj.objects[d:sub(11)]
				o.cx = o2.cx
				o.cy = o2.cy
				o.cz = o2.cz
				for i,v in ipairs(o.vertices) do
					o.vertices[i] = {v[1] - o.cx, v[2] - o.cy, v[3] - o.cz}
				end
			end
		end
	end
	
	
	--create particle systems
	if not obj.noParticleSystem then
		self:addParticlesystems(obj)
	end
	
	
	--remove empty objects
	for d,s in pairs(obj.objects) do
		if s.vertices and #s.vertices == 0 then
			obj.objects[d] = nil
		end
	end
	
	
	--calculate bounding box
	obj.boundingBox = newBoundaryBox()
	local total = 0
	for d,s in pairs(obj.objects) do
		total = total + 1
		if s.boundingBox then
			--convert loaded boundaries (e.g. .3do files)
			s.boundingBox.first = vec3(s.boundingBox.first)
			s.boundingBox.second = vec3(s.boundingBox.first)
			s.boundingBox.dimensions = vec3(s.boundingBox.first)
			s.boundingBox.center = vec3(s.boundingBox.first)
		else
			s.boundingBox = newBoundaryBox()
			
			--scan all vertices
			for i,v in ipairs(s.vertices) do
				local pos = vec3(v)
				s.boundingBox.first = s.boundingBox.first:min(pos)
				s.boundingBox.second = s.boundingBox.second:max(pos)
				s.boundingBox.center = s.boundingBox.center + pos
			end
			
			s.boundingBox.center = s.boundingBox.center / #s.vertices
			s.boundingBox.dimensions = s.boundingBox.second - s.boundingBox.first
			s.boundingBox.size = math.max((s.boundingBox.dimensions * 0.5):length(), s.boundingBox.size)
		end
		
		obj.boundingBox.first = s.boundingBox.first:min(obj.boundingBox.first)
		obj.boundingBox.second = s.boundingBox.second:max(obj.boundingBox.second)
		obj.boundingBox.center = s.boundingBox.center + obj.boundingBox.center
		
		obj.boundingBox.size = math.max(obj.boundingBox.size, s.boundingBox.size)
	end
	obj.boundingBox.center = obj.boundingBox.center / total
	obj.boundingBox.dimensions = obj.boundingBox.second - obj.boundingBox.first
	
	
	--extract collisions
	for dd,s in pairs(obj.objects) do
		local pos = s.name:find("COLLISION")
		if pos then
			local d = #s.name:sub(pos + 10) == 0 and "collision" or s.name:sub(pos + 10)
			obj.collisions = obj.collisions or { }
			obj.collisionCount = (obj.collisionCount or 0) + 1
			obj.collisions[d] = self:getCollisionData(s)
			obj.objects[dd] = nil
		end
	end
	
	
	--post load materials
	for d,s in pairs(obj.materials) do
		s.dir = s.dir or obj.textures or obj.dir
		self:finishMaterial(s, obj)
	end
	
	
	--create meshes
	if not obj.noMesh then
		for d,o in pairs(obj.objects) do
			if not o.disabled then
				self:createMesh(o)
			end
		end
	end
	
	
	--cleaning up
	if obj.cleanup ~= false then
		for d,s in pairs(obj.objects) do
			if obj.cleanup then
				s.vertices = nil
				s.faces = nil
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
	if obj.export3do then
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
	local empty = {0, 0, 0, 0}
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
				tangent[1]*0.5+0.5, tangent[2]*0.5+0.5, tangent[3]*0.5+0.5, 0.0
			)
		elseif o.meshType == "textured_array" then
			local tangent = o.tangents[i] or empty
			o.mesh:setVertex(i,
				vertex[1], vertex[2], vertex[3], o.extras[i] or 1,
				texCoord[1], texCoord[2], texCoord[3], 
				normal[1]*0.5+0.5, normal[2]*0.5+0.5, normal[3]*0.5+0.5, 0.0,
				tangent[1]*0.5+0.5, tangent[2]*0.5+0.5, tangent[3]*0.5+0.5, 0.0
			)
		elseif o.meshType == "simple" then
			local material = o.materials[i] or empty
			local color = o.colors[i] or material.color or empty
			
			local specular = material.specular or material[1] or 0
			local glossiness = material.glossiness or material[2] or 0
			local emission = material.emission or material[3] or 0
			if type(emission) == "table" then
				emission = emission[1] * 0.33 + emission[2] * 0.33 + emission[3] * 0.33
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