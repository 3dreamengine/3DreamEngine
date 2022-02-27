--[[
#dae - COLLADA
--]]

--load space seperated arrays as floats or as strings
local function loadFloatArray(arr)
	local t = { }
	for w in arr:gmatch("%S+") do
		table.insert(t, tonumber(w))
	end
	return t
end

local function loadVecArray(arr, stride)
	local t = { }
	local i = stride
	for w in arr:gmatch("%S+") do
		i = i + 1
		if i > stride then
			table.insert(t, { })
			i = 1
		end
		table.insert(t[#t], tonumber(w))
	end
	return t
end

local function loadArray(arr)
	local t = { }
	for w in arr:gmatch("%S+") do
		table.insert(t, w)
	end
	return t
end

--load entire tree and index all IDs
local indices
local function indexTree(node)
	for key,child in pairs(node) do
		if type(child) == "table" and key ~= "_attr" then
			indexTree(child)
		end
	end
	
	if node._attr and node._attr.id then
		indices[node._attr.id] = node
		indices["#" .. node._attr.id] = node
	end
end

--returns the data for a given source
local function getInput(id)
	local s = indices[id]
	if s.Name_array then
		return loadArray(s.Name_array[1][1])
	elseif s.float_array or s.int_array then
		local stride = s.technique_common and s.technique_common[1].accessor and tonumber(s.technique_common[1].accessor[1]._attr.stride)
		if stride and stride > 1 then
			return loadVecArray((s.float_array or s.int_array)[1][1], stride)
		else
			return loadFloatArray((s.float_array or s.int_array)[1][1])
		end
	elseif s.input then
		return getInput(s.input[1]._attr.source)
	else
		error("unknown input data type")
	end
end

--loads an array of inputs
local function loadInputs(s, idxs)
	local idxs = idxs or (s.p or s.v) and loadFloatArray((s.p or s.v)[1][1])
	
	--use the max offset to determine data width
	local fields = 0
	for _,input in ipairs(s.input) do
		local offset = 1 + (tonumber(input._attr.offset) or 0)
		fields = math.max(fields, offset)
	end
	
	local data = { }
	local vertexMapping = { }
	for _,input in ipairs(s.input) do
		local set = 1 + tonumber(input._attr.set or "0")
		local typ = input._attr.semantic
		local array = getInput(input._attr.source)
		local offset = 1 + (tonumber(input._attr.offset) or 0)
		
		data[typ] = data[typ] or { }
		data[typ][set] = data[typ][set] or { }
		
		for vertex = 1, idxs and (#idxs / fields) or #array do
			local id = idxs and (idxs[(vertex - 1) * fields + offset] + 1) or vertex
			data[typ][set][vertex] = array[id]
			
			if typ == "VERTEX" then
				vertexMapping[vertex] = id
			end
		end
	end
	
	return data, vertexMapping
end

local function addMesh(self, obj, mat, id, inputs, vertexMapping, meshData, vcount)
	--create mesh
	local material = mat and self.materialLibrary[mat.name] or mat or self:newMaterial()
	local m = self:newMesh(id, material)
	
	m.vertexMapping = vertexMapping
	
	meshData[id] = meshData[id] or { }
	table.insert(meshData[id], m)
	
	--flip UV
	for _,array in pairs(inputs["TEXCOORD"] or {}) do
		for i,v in ipairs(array) do
			array[i] = {v[1], 1.0 - v[2]}
		end
	end
	
	--insert values
	local translate = {
		["VERTEX"] = "vertices",
		["NORMAL"] = "normals",
		["TEXCOORD"] = "texCoords",
		["COLOR"] = "colors",
		["TEXTANGENT"] = "tangents",
		["TANGENT"] = "tangents",
	}
	for from, to in pairs(translate) do
		for set, array in pairs(inputs[from] or { }) do
			m[set == 1 and to or (to .. set)] = array
		end
	end
	
	--construct faces
	local i = 1
	for face = 1, type(vcount) == "number" and vcount or #vcount do
		assert(i < #m.vertices, #m.vertices)
		local verts = type(vcount) == "number" and 3 or vcount[face]
		if verts == 3 then
			--tris
			table.insert(m.faces, {i, i+1, i+2})
		else
			--triangulates, fan style
			for f = 1, verts-2 do
				table.insert(m.faces, {i, i+f, i+f+1})
			end
		end
		i = i + verts
	end
end

return function(self, obj, path)
	local xml2lua = require(self.root .. "/libs/xml2lua/xml2lua")
	local handler = require(self.root .. "/libs/xml2lua/tree"):new()
	
	--parse
	local file = love.filesystem.read(path)
	xml2lua.parser(handler):parse(file)
	
	local correction = mat4:getRotateX(-math.pi/2)
	local root = handler.root.COLLADA[1]
	
	--get id indices
	indices = { }
	indexTree(root)
	
	
	--load skin controller
	local controllers = { }
	for _, library in ipairs(root.library_controllers or { }) do
		for _,controller in ipairs(library.controller or { }) do
			local skin = controller.skin[1]
			if skin then
				local c = {
					weights = { },
					joints = { },
					mesh = skin._attr.source:sub(2)
				}
				controllers[controller._attr.id] = c
				
				--load bind transform
				local data = loadInputs(skin.joints[1])
				c.jointNames = data.JOINT[1]
				
				local m = data.INV_BIND_MATRIX[1]
				c.inverseBindMatrices = { }
				for i,v in ipairs(m) do
					c.inverseBindMatrices[i] = mat4(v)
				end
				
				--load data
				local data = loadInputs(skin.vertex_weights[1])
				local vcounts = loadFloatArray(skin.vertex_weights[1].vcount[1][1])
				local vertex = 0
				c.weights = { }
				c.joints = { }
				for i,vertexCount in ipairs(vcounts) do
					c.weights[i] = { }
					c.joints[i] = { }
					for i2 = 1, vertexCount do
						vertex = vertex + 1
						c.weights[i][i2] = data.WEIGHT[1][vertex]
						c.joints[i][i2] = data.JOINT[1][vertex]
					end
				end
				
				--sort weights
				for idx, w in ipairs(c.weights) do
					local n = #w
					repeat
						local newn = 0
						for i = 2, n do
							if w[i - 1] < w[i] then
								w[i - 1], w[i] = w[i], w[i - 1]
								c.joints[idx][i - 1], c.joints[idx][i] = c.joints[idx][i], c.joints[idx][i - 1]
								newn = i
							end
						end
						n = newn
					until n < 1
				end
				
				--map joints to integers for easier processing
				local mapping = { }
				for i,v in ipairs(c.jointNames) do
					mapping[v] = i - 1
				end
				for _,joints in ipairs(c.joints) do
					for i, j in ipairs(joints) do
						joints[i] = mapping[j]
					end
				end
			end
		end
	end

	
	--load materials
	local materials = { }
	for _,library in ipairs(root.library_materials or { }) do
		for _,mat in ipairs(library.material) do
			local name = mat._attr.name or mat._attr.id
			local material = self:newMaterial(name)
			materials[mat._attr.id] = material
		end
	end
	
	
	--load geometry
	local meshData = { }
	for _,library in ipairs(root.library_geometries or { }) do
		for _,geometry in ipairs(library.geometry) do
			if geometry.mesh then
				local mesh = geometry.mesh[1]
				local id = geometry._attr.id
				
				--load all the buffers
				if mesh.triangles then
					for _,t in ipairs(mesh.triangles) do
						local inputs, vertexMapping = loadInputs(t)
						local matId = t._attr.material
						addMesh(self, obj, matId and materials[matId], id, inputs, vertexMapping, meshData, tonumber(t._attr.count))
					end
				end
				
				if mesh.polylist then
					for _,p in ipairs(mesh.polylist) do
						local inputs, vertexMapping = loadInputs(p)
						local vcount = loadFloatArray(p.vcount[1][1])
						local matId = p._attr.material
						addMesh(self, obj, matId and materials[matId], id, inputs, vertexMapping, meshData, vcount)
					end
				end
				
				if mesh.polygons then
					for _,p in ipairs(mesh.polygons) do
						local idxs = { }
						local vcount = { }
						local matId = p._attr.material
						
						--combine polygons
						for _,p in ipairs(mesh.polygons.p) do
							local a = loadFloatArray(p[1])
							for _,v in ipairs(a) do
								table.insert(idxs, v)
							end
							table.insert(vcount, #a)
						end
						
						local inputs, _, vertexMapping = loadInputs(mesh.polygons[1], idxs)
						addMesh(self, obj, matId and materials[matId], id, inputs, vertexMapping, meshData, vcount)
					end
				end
			end
		end
	end
	
	
	--load light
	local lightIDs = { }
	for _,library in ipairs(root.library_lights or { }) do
		for d,light in ipairs(library.light) do
			local l = self:newLight()
			l:setName(light._attr.name)
			lightIDs[light._attr.id] = l
			
			if light.extra and light.extra[1] and light.extra[1].technique and light.extra[1].technique[1] then
				local dat = light.extra[1].technique[1]
				
				l:setColor(dat.red and tonumber(dat.red[1][1]) or 1.0, dat.green and tonumber(dat.green[1][1]) or 1.0, dat.blue and tonumber(dat.blue[1][1]) or 1.0)
				l:setBrightness(dat.energy and tonumber(dat.energy[1][1]) or 1.0)
			end
		end
	end
	
	--todo only matrix is supported
	local function getTransform(s)
		return s.matrix and mat4(loadFloatArray(s.matrix[1][1])) or mat4:getIdentity()
	end
	
	local function skeletonLoader(nodes)
		local skel = { }
		for d,s in ipairs(nodes) do
			if s._attr.type == "JOINT" then
				local name = s._attr.sid
				
				skel[name] = {
					name = name,
				}
				
				if s.node then
					skel[name].children = skeletonLoader(s.node)
				end
			end
		end
		return skel
	end
	
	local function addMeshesToObject(name, obj, meshes, transform, controller)
		for i, mesh in ipairs(meshes or {}) do
			local n = i == 1 and name or name .. "." .. i
			obj.meshes[n] = mesh:clone()
			obj.meshes[n]:setName(n)
			obj.meshes[n].transform = transform
			
			if controller then
				obj.meshes[n].weights = { }
				obj.meshes[n].joints = { }
				
				for d,s in ipairs(mesh.vertexMapping) do
					obj.meshes[n].weights[d] = controller.weights[s]
					obj.meshes[n].joints[d] = controller.joints[s]
				end
				
				obj.meshes[n].jointNames = controller.jointNames
				obj.meshes[n].inverseBindMatrices = controller.inverseBindMatrices
			end
		end
	end
	
	--travers the scene graph
	local function loadNodes(nodes, parentTransform)
		for _,s in ipairs(nodes) do
			local name = s._attr.name or s._attr.id
			local transform = getTransform(s)
			transform = parentTransform and parentTransform * transform or transform
			if s.instance_geometry then
				--object
				local id = s.instance_geometry[1]._attr.url:sub(2)
				local mesh = meshData[id]
				addMeshesToObject(name, obj, mesh, transform)
			elseif s.instance_controller then
				local id = s.instance_controller[1]._attr.url:sub(2)
				local controller = controllers[id]
				local mesh = meshData[controller.mesh]
				addMeshesToObject(name, obj, mesh, transform, controller)
			elseif s.instance_light then
				--light source
				local id = s.instance_light[1]._attr.url:sub(2)
				local l = lightIDs[id]
				l:setPosition(transform[4], transform[8], transform[12])
				l:setName(name)
				obj.lights[id] = l:clone()
			elseif s.instance_camera then
				--todo
			elseif s.instance_node then
				--todo
			elseif s._attr.type == "JOINT" then
				--start of a skeleton
				--we treat skeletons different than nodes and will use a different traverser here
				if s.node then
					obj.skeleton = self:newSkeleton(skeletonLoader(nodes))
				end
			end
			
			--children
			if s.node and s._attr.type ~= "JOINT" then
				loadNodes(s.node, transform)
			end
		end
	end
	
	
	--cleanup
	for d,s in pairs(obj.meshes) do
		s.vertexMapping = nil
	end
	
	
	--load scenes, scenes are flattened into one object
	for _,scene in ipairs(root.library_visual_scenes or { }) do
		for _,visual_scene in ipairs(scene.visual_scene or { }) do
			loadNodes(visual_scene.node)
		end
	end
	
	
	--load animations
	local animations = { }
	local function loadAnimation(anim)
		local animation = self:newAnimation()
		
		for _,a in ipairs(anim.animation) do
			if a.animation and a.channel then
				print("WARNING: dae file contains too complex animations, see docu for more information.")
			end
			if a.animation then
				loadAnimation(a)
			elseif a.channel then
				--parse sources
				local sources = { }
				for d,s in ipairs(a.source) do
					sources[s._attr.id] = s.float_array and loadFloatArray(s.float_array[1][1])
				end
				for d,s in ipairs(a.sampler[1].input) do
					sources[s._attr.semantic] = sources[s._attr.source:sub(2)]
				end
				
				--get matrices
				local id = a.channel[1]._attr.target
				local name = indices[id:sub(1, -11)] and indices[id:sub(1, -11)]._attr.sid
				assert(name, "animation output channel refers to unknown id " .. id)
				animation.frames[name] = { }
				for i = 1, #sources.OUTPUT / 16 do
					local m = mat4(unpack(sources.OUTPUT, i*16-15, i*16))
					table.insert(animation.frames[name], {
						time = sources.INPUT[i],
						rotation = quat.fromMatrix(m:subm()),
						position = vec3(m[4], m[8], m[12]),
					})
				end
			end
		end
		
		animation:finish()
		if animation.length > 0 then
			obj.animations[anim._attr.name or anim._attr.id] = animation
		end
	end
	
	--load animations
	for _,animations in ipairs(root.library_animations or { }) do
		for _,animation in ipairs(animations.animation or { }) do
			if animation.animation then
				loadAnimation(animation)
			end
		end
	end
end