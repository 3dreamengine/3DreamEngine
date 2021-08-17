--[[
#part of the 3DreamEngine by Luke100000
bufferFunctions.lua - contains library relevant functions with focus on buffer modifications
--]]

local lib = _3DreamEngine

function lib:applyTransform(s, transform)
	if type(s) == "userdata" then
		--parse mesh format
		local f = s:getVertexFormat()
		local indices = { }
		local index = 1
		for d,s in ipairs(f) do
			indices[s[1]] = index
			index = index + s[3]
		end
		
		--normal transformation
		local subm = transform:subm()
		
		for i = 1, s:getVertexCount() do
			local data = {s:getVertex(i)}
			
			--transform vertices
			local p = indices.VertexPosition
			if p then
				data[p], data[p+1], data[p+2] = transform * vec3(data[p], data[p+1], data[p+2])
			end
			
			--transform normals
			local p = indices.VertexNormal
			if p then
				data[p], data[p+1], data[p+2] = subm * vec3(data[p], data[p+1], data[p+2])
			end
			
			s:setVertex(i, unpack(data))
		end
	elseif s.class == "mesh" then
		if s then
			self:applyTransform(s.mesh, s.transform)
		else
			assert(s.vertices and s.normals, "object has been cleaned up!")
			
			--normal transforation
			local subm = transform:subm()
			
			for i = 1, #s.vertices do
				--transform vertices
				s.vertices[i] = transform * vec3(s.vertices[i])
				
				--transform normals
				s.normals[i] = subm * vec3(s.normals[i])
			end
		end
		s.transform = nil
	elseif s.class == "object" then
		for d,s in ipairs(s) do
			self:applyTransform(s)
		end
	else
		error("mesh, object or mesh expected")
	end
end

--merge all meshes of an object and concat all buffer together
--it uses a random material and therfore either requires baking afterwards or only identical materials in the first place
--it returns a cloned object with only one mesh
function lib:mergeMeshes(obj)
	local final = obj:clone()
	local o = self:newMesh("merged", false, final.args.meshType)
	final.meshes = {merged = o}
	
	for d,s in pairs(obj.meshes) do
		o.material = s.material
		o.jointIDs = s.jointIDs
		if o.jointIDs then
			o.transform = s.transform
		end
		break
	end
	
	--get valid objects
	local meshes = { }
	for d,s in pairs(obj.meshes) do
		if not s.LOD_max or s.LOD_max >= math.huge then
			if s.tags.merge ~= false then
				meshes[d] = s
			end
		end
	end
	
	--check which buffers are necessary
	local buffers = {
		"vertices",
		"normals",
		"texCoords",
		"colors",
		"materials",
		"weights",
		"joints",
	}
	local found = { }
	for d,s in pairs(meshes) do
		for _,buffer in pairs(buffers) do
			if s[buffer] then
				found[buffer] = true
			end
		end
	end
	
	assert(found.vertices, "object has been cleaned up!")
	
	local defaults = {
		vertices = vec3(0, 0, 0),
		normals = vec3(0, 0, 0),
		texCoords = vec2(0, 0),
	}
	
	--merge buffers
	local startIndices = { }
	for d,s in pairs(meshes) do
		local index = #o.vertices
		startIndices[d] = index
		
		local transform, transformNormal
		if not s.jointIDs then
			transform = s.transform
			transformNormal = transform and transform:subm()
		end
		
		for buffer,_ in pairs(found) do
			o[buffer] = o[buffer] or { }
			for i = 1, #s.vertices do
				local v = s[buffer] and s[buffer][i] or defaults[buffer] or false
				
				if transform then
					if buffer == "vertices" then
						v = transform * vec3(v)
					elseif buffer == "normals" then
						v = transformNormal * vec3(v)
					end
				end
				
				if buffer == "materials" and not v then
					v = s.material
				end
				
				o[buffer][index + i] = v
			end
		end
	end
	
	--merge faces
	for d,s in pairs(meshes) do
		for _,face in ipairs(s.faces) do
			local i = startIndices[d]
			table.insert(o.faces, {face[1] + i, face[2] + i, face[3] + i})
		end
	end
	
	final:updateBoundingBox()
	
	return final
end

--add tangents buffer
local empty = {0, 0, 0}
function lib:calcTangents(o)
	o.tangents = { }
	for i = 1, #o.vertices do
		o.tangents[i] = {0, 0, 0, 0}
	end
	
	for i,f in ipairs(o.faces) do
		--vertices
		local v1 = o.vertices[f[1]] or empty
		local v2 = o.vertices[f[2]] or empty
		local v3 = o.vertices[f[3]] or empty
		
		--tex coords
		local uv1 = o.texCoords[f[1]] or empty
		local uv2 = o.texCoords[f[2]] or empty
		local uv3 = o.texCoords[f[3]] or empty
		
		local tangent = { }
		
		local edge1 = {v2[1] - v1[1], v2[2] - v1[2], v2[3] - v1[3]}
		local edge2 = {v3[1] - v1[1], v3[2] - v1[2], v3[3] - v1[3]}
		local edge1uv = {uv2[1] - uv1[1], uv2[2] - uv1[2]}
		local edge2uv = {uv3[1] - uv1[1], uv3[2] - uv1[2]}
		
		local cp = edge1uv[1] * edge2uv[2] - edge1uv[2] * edge2uv[1]
		
		if cp ~= 0.0 then
			--handle clockwise-uvs
			local clockwise = mat3(uv1[1], uv1[2], 1, uv2[1], uv2[2], 1, uv3[1], uv3[2], 1):det() > 0
			
			for i = 1, 3 do
				tangent[i] = (edge1[i] * edge2uv[2] - edge2[i] * edge1uv[2]) / cp
			end
			
			--sum up tangents to smooth across shared vertices
			for i = 1, 3 do
				o.tangents[f[i]][1] = o.tangents[f[i]][1] + tangent[1]
				o.tangents[f[i]][2] = o.tangents[f[i]][2] + tangent[2]
				o.tangents[f[i]][3] = o.tangents[f[i]][3] + tangent[3]
				o.tangents[f[i]][4] = o.tangents[f[i]][4] + (clockwise and 1 or 0)
			end
		end
	end
	
	--normalize
	for i,f in ipairs(o.tangents) do
		local l = math.sqrt(f[1]^2 + f[2]^2 + f[3]^2)
		f[1] = f[1] / l
		f[2] = f[2] / l
		f[3] = f[3] / l
	end	
	
	--complete smoothing step
	for i,f in ipairs(o.tangents) do
		local n = o.normals[i]
		
		--Gram-Schmidt orthogonalization
		local dot = (f[1] * n[1] + f[2] * n[2] + f[3] * n[3])
		f[1] = f[1] - n[1] * dot
		f[2] = f[2] - n[2] * dot
		f[3] = f[3] - n[3] * dot
		
		local l = math.sqrt(f[1]^2 + f[2]^2 + f[3]^2)
		f[1] = f[1] / l
		f[2] = f[2] / l
		f[3] = f[3] / l
	end
end

lib.meshTypeFormats = {
	textured = {
		{"VertexPosition", "float", 4},     -- x, y, z
		{"VertexTexCoord", "float", 2},     -- UV
		{"VertexNormal", "byte", 4},        -- normal
		{"VertexTangent", "byte", 4},       -- normal tangent
	},
	textured_array = {
		{"VertexPosition", "float", 4},     -- x, y, z
		{"VertexTexCoord", "float", 3},     -- UV
		{"VertexNormal", "byte", 4},        -- normal
		{"VertexTangent", "byte", 4},       -- normal tangent
	},
	simple = {
		{"VertexPosition", "float", 4},     -- x, y, z
		{"VertexNormal", "byte", 4},        -- normal
		{"VertexMaterial", "float", 3},     -- roughness, metallic, emissive
		{"VertexColor", "byte", 4},         -- color
	},
	material = {
		{"VertexPosition", "float", 4},     -- x, y, z
		{"VertexNormal", "byte", 4},        -- normal
		{"VertexMaterial", "float", 1},     -- material
	},
}

--takes an final and face table and generates the mesh and vertexMap
--note that .3do files has it's own mesh loader
function lib:createMesh(obj)
	if obj.class == "object" then
		if not obj.linked then
			for d,o in pairs(obj.meshes) do
				lib:createMesh(o)
			end
			
			for d,o in pairs(obj.objects) do
				lib:createMesh(o)
			end
		end
	elseif obj.class == "mesh" then
		if not obj.faces then
			return
		end
		
		--set up vertex map
		local vertexMap = { }
		for d,f in ipairs(obj.faces) do
			vertexMap[#vertexMap+1] = f[1]
			vertexMap[#vertexMap+1] = f[2]
			vertexMap[#vertexMap+1] = f[3]
		end
		
		--calculate vertex normals and uv normals
		if obj.meshType == "textured" or obj.meshType == "textured_array" then
			self:calcTangents(obj)
		end
		
		--create mesh
		local meshLayout = table.copy(self.meshTypeFormats[obj.meshType])
		obj.mesh = love.graphics.newMesh(meshLayout, #obj.vertices, "triangles", "static")
		
		--vertex map
		obj.mesh:setVertexMap(vertexMap)
		
		--set vertices
		local empty = {1, 0, 1, 1}
		for i = 1, #obj.vertices do
			local vertex = obj.vertices[i] or empty
			local normal = obj.normals[i] or empty
			local texCoord = obj.texCoords[i] or empty
			
			if obj.meshType == "textured" then
				local tangent = obj.tangents[i] or empty
				obj.mesh:setVertex(i,
					vertex[1], vertex[2], vertex[3], 1,
					texCoord[1], texCoord[2],
					normal[1]*0.5+0.5, normal[2]*0.5+0.5, normal[3]*0.5+0.5, 0.0,
					tangent[1]*0.5+0.5, tangent[2]*0.5+0.5, tangent[3]*0.5+0.5, tangent[4] or 0.0
				)
			elseif obj.meshType == "textured_array" then
				local tangent = obj.tangents[i] or empty
				obj.mesh:setVertex(i,
					vertex[1], vertex[2], vertex[3], 1,
					texCoord[1], texCoord[2], texCoord[3], 
					normal[1]*0.5+0.5, normal[2]*0.5+0.5, normal[3]*0.5+0.5, 0.0,
					tangent[1]*0.5+0.5, tangent[2]*0.5+0.5, tangent[3]*0.5+0.5, tangent[4] or 0.0
				)
			elseif obj.meshType == "simple" then
				local material = obj.materials[i] or empty
				local color = obj.colors[i] or material.color or empty
				
				local roughness = material.roughness or material[1] or 0
				local metallic = material.metallic or material[2] or 0
				local emission = material.emission or material[3] or 0
				if type(emission) == "table" then
					emission = emission[1] / 3 + emission[2] / 3 + emission[3] / 3
				end
				
				obj.mesh:setVertex(i,
					vertex[1], vertex[2], vertex[3], 1,
					normal[1]*0.5+0.5, normal[2]*0.5+0.5, normal[3]*0.5+0.5, 0.0,
					roughness, metallic, emission,
					color[1], color[2], color[3], color[4]
				)
			elseif obj.meshType == "material" then
				obj.mesh:setVertex(i,
					vertex[1], vertex[2], vertex[3], 1,
					normal[1]*0.5+0.5, normal[2]*0.5+0.5, normal[3]*0.5+0.5, 0.0,
					texCoord
				)
			end
		end
	else
		error("object or mesh expected")
	end
end