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
	local idxs = idxs or loadFloatArray(s.p[1][1])
	
	--use the max offset to determine data width
	local fields = 0
	for _,input in ipairs(s.input) do
		fields = math.max(fields, tonumber(input._attr.offset) + 1)
	end
	
	local data = { }
	local vertexMapping = { }
	for _,input in ipairs(s.input) do
		local set = 1 + tonumber(input._attr.set or "0")
		local typ = input._attr.semantic
		local array = getInput(input._attr.source)
		local offset = 1 + tonumber(input._attr.offset)
		
		data[typ] = data[typ] or { }
		data[typ][set] = data[typ][set] or { }
		
		for vertex = 1, #idxs / fields do
			local id = idxs[(vertex - 1) * fields + offset]
			data[typ][set][vertex] = array[id + 1]
			
			if typ == "VERTEX" then
				vertexMapping[vertex] = id + 1
			end
		end
	end
	
	return data, vertexMapping
end

--loads an array of inputs
local function loadWeightsInputs(s)
	local vcounts = s.vcount and loadFloatArray(s.vcount[1][1])
	local idxs = idxs or loadFloatArray(s.v[1][1])
	
	--use the max offset to determine data width
	local fields = 0
	for _,input in ipairs(s.input) do
		fields = math.max(fields, tonumber(input._attr.offset) + 1)
	end
	
	local data = { }
	for _,input in ipairs(s.input) do
		local typ = input._attr.semantic
		local array = getInput(input._attr.source)
		local offset = 1 + tonumber(input._attr.offset)
		
		data[typ] = data[typ] or { }
		local index = 0
		for vertex, count in ipairs(vcounts) do
			data[typ][vertex] = { }
			for v = 1, count do
				index = index + 1
				local id = (index-1) * fields + offset
				data[typ][vertex][v] = array[idxs[id] + 1]
			end
		end
	end
	
	return data
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
	local jointMapping = { }
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
				
				--load data
				local data = loadWeightsInputs(skin.vertex_weights[1])
				c.weights = data.WEIGHT
				c.joints = data.JOINT
				
				--sort weights
				for idx = 1, #c.weights do
					local n = #c.weights[idx]
					repeat
						local newn = 0
						for i = 2, n do
							if c.weights[idx][i - 1] < c.weights[idx][i] then
								c.weights[idx][i - 1], c.weights[idx][i] = c.weights[idx][i], c.weights[idx][i - 1]
								c.joints[idx][i - 1], c.joints[idx][i] = c.joints[idx][i], c.joints[idx][i - 1]
								newn = i
							end
						end
						n = newn
					until n < 1
				end
				
				--map joints to integers for easier processing
				local lastId = 0
				for d,s in pairs(jointMapping) do
					lastId = lastId + 1
				end
				for _,joints in ipairs(c.joints) do
					for i, j in ipairs(joints) do
						if not jointMapping[j] then
							lastId = lastId + 1
							jointMapping[j] = lastId
						end
						joints[i] = jointMapping[j]
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
	
	local function skeletonLoader(nodes, parentTransform)
		local skel = { }
		for d,s in ipairs(nodes) do
			if s._attr.type == "JOINT" then
				local name = s._attr.sid
				
				local transform = getTransform(s)
				local bindTransform = parentTransform and parentTransform * transform or transform
				
				skel[name] = {
					name = name,
					bindTransform = transform,
					inverseBindTransform = bindTransform:invert(),
				}
				
				if s.node then
					skel[name].children = skeletonLoader(s.node, bindTransform)
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
					obj.skeleton = self:newSkeleton(skeletonLoader(nodes), jointMapping)
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