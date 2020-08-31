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

function lib:newSubObject(name, obj, mat)
	--guess shaderType if not specified based on textures used
	local shaderType = obj.shaderType
	if not shaderType then
		if lib.defaultShaderType then
			shaderType = lib.defaultShaderType
		else
			shaderType = "simple"
			
			if mat.tex_albedo or mat.tex_normal then
				shaderType = "Phong"
			end
		end
	end
	
	local meshType = self.shaderLibrary.base[shaderType].meshType
	
	local o = {
		name = name,
		material = mat,
		final = { },
		faces = { },
		shaderType = shaderType,
		meshType = meshType,
	}
	
	return o
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
	}
	
	--get name and dir
	local n = self:split(path, "/")
	name = n[#n] or path
	local dir = #n > 1 and table.concat(n, "/", 1, #n-1) or ""
	
	local obj = {
		materials = {
			None = args.material or self:newMaterial()
		},
		objects = { },
		positions = { },
		
		path = path, --absolute path to object
		name = name, --name of object
		dir = dir, --dir containing the object
		
		--additional args settings
		noParticleSystem = args.noParticleSystem == nil and args.noMesh or args.noParticleSystem,
		
		--the object transformation
		transform = mat4:getIdentity(),
	}
	setmetatable(obj, self.operations)
	
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
		local pos = s.name:find("POS")
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
			
			local r = 0
			for i,v in ipairs(s.final) do
				r = r + math.sqrt((v[1] - x)^2 + (v[2] - y)^2 + (v[3] - z)^2)
			end
			r = r / #s.final
			
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
			for i,v in ipairs(o.final) do
				minX = math.min(minX or v[1], v[1])
				minY = math.min(minY or v[2], v[2])
				minZ = math.min(minZ or v[3], v[3])
			end
			
			o.x = math.floor((minX or 0) + 0.25)
			o.y = math.floor((minY or 0) + 0.25)
			o.z = math.floor((minZ or 0) + 0.25)
			
			for i,v in ipairs(o.final) do
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
				for i,v in ipairs(o.final) do
					x = x + v[1]
					y = y + v[2]
					z = z + v[3]
				end
				
				o.cx = x / #o.final
				o.cy = y / #o.final
				o.cz = z / #o.final
				
				for i,v in ipairs(o.final) do
					v[1] = v[1] - o.cx
					v[2] = v[2] - o.cy
					v[3] = v[3] - o.cz
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
				for i,v in ipairs(o.final) do
					v[1] = v[1] - o.cx
					v[2] = v[2] - o.cy
					v[3] = v[3] - o.cz
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
		if s.final and #s.final == 0 then
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
			for i,v in ipairs(s.final) do
				local pos = vec3(v)
				s.boundingBox.first = s.boundingBox.first:min(pos)
				s.boundingBox.second = s.boundingBox.second:max(pos)
				s.boundingBox.center = s.boundingBox.center + pos
			end
			
			s.boundingBox.center = s.boundingBox.center / #s.final
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
		s.dir = s.dir or obj.textures or dir
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
	if not obj.noCleanup then
		for d,s in pairs(obj.objects) do
			s.faces = nil
			s.final = nil
		end
		collectgarbage()
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
		self:calcTangents(o.final, vertexMap)
	end
	
	--create mesh
	local meshLayout = self.meshTypeFormats[o.meshType]
	o.mesh = love.graphics.newMesh(meshLayout, #o.final, "triangles", "static")
	
	--vertex map
	o.mesh:setVertexMap(vertexMap)
	
	--set vertices
	for d,s in ipairs(o.final) do
		if o.meshType == "textured" then
			o.mesh:setVertex(d,
				s[1], s[2], s[3], s[4],
				s[9], s[10],
				s[5]*0.5+0.5, s[6]*0.5+0.5, s[7]*0.5+0.5, 0.0,
				s[11]*0.5+0.5, s[12]*0.5+0.5, s[13]*0.5+0.5, 0.0
			)
		elseif o.meshType == "textured_array" then
			o.mesh:setVertex(d,
				s[1], s[2], s[3], s[4],
				s[9], s[10], s[8],
				s[5]*0.5+0.5, s[6]*0.5+0.5, s[7]*0.5+0.5, 0.0,
				s[11]*0.5+0.5, s[12]*0.5+0.5, s[13]*0.5+0.5, 0.0
			)
		elseif o.meshType == "simple" then
			local c = s[8].color
			o.mesh:setVertex(d,
				s[1], s[2], s[3], s[4],
				s[5], s[6], s[7],
				s[8].specular, s[8].glossiness, s[8].emission or 0.0,
				c[1], c[2], c[3], c[4]
			)
		elseif o.meshType == "material" then
			local c = s[8].color
			o.mesh:setVertex(d,
				s[1], s[2], s[3], s[4],
				s[5], s[6], s[7],
				s[8]
			)
		end
	end
end