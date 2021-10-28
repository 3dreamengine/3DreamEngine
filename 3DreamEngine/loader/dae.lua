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
	local i = 0
	for w in arr:gmatch("%S+") do
		i = i + 1
		if i > stride then
			table.insert(t, { })
			i = 0
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
		--todo meh
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
		return loadFloatArray((s.float_array or s.int_array)[1][1])
	elseif s.input then
		return getInput(s.input[1]._attr.source)
	else
		error("unknown input data type")
	end
end

--loads an array of inputs
local function loadInputs(s, stride, idxs)
	local vcounts = s.vcount and loadFloatArray(s.vcount[1][1]) or { }
	local idxs = idxs or loadFloatArray((s.v or s.p)[1][1])
	
	--use the max offset to determine data width
	local fields = 0
	for _,input in ipairs(s.input) do
		fields = math.max(fields, tonumber(input._attr.offset) + 1)
	end
	
	local data = { }
	for _,input in ipairs(s.input) do
		local array = getInput(input._attr.source)
		local offset = 1 + tonumber(input._attr.offset)
		local set = 1 + tonumber(input._attr.set or "0")
		local typ = input._attr.semantic
		local count = stride and stride[typ] or vcounts[vertex] or 1
		data[typ] = data[typ] or { }
		data[typ][set] = data[typ][set] or { }
		
		local valueIndex = 0
		for vertex = 1, #idxs / fields do
			data[typ][set][vertex] = { }
			local id = idxs[valueIndex * fields + offset]
			for v = 1, count do
				data[typ][set][vertex][v] = array[id * count + v]
			end
			valueIndex = valueIndex + 1
		end
	end
	
	return data, vcounts
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
	if root.library_controllers[1] then
		for _,controller in ipairs(root.library_controllers[1].controller or { }) do
			local skin = controller.skin[1]
			if skin then
				local c = {
					weights = { },
					joints = { },
					mesh = skin._attr.source:sub(2)
				}
				controllers[controller._attr.id] = c
				
				--load data
				local data = loadInputs(skin.vertex_weights[1])
				c.weights = data.WEIGHT[1]
				c.joints = data.JOINT[1]
				
				--normalize weights and limit to 4 (GPU limit)
				for i = 1, #c.weights do
					while #c.weights[i] > 4 do
						local min, best = math.huge, 1
						for d,s in ipairs(c.weights[i]) do
							if s < min then
								min = s
								best = d
							end
						end
						table.remove(c.joints[i], best)
						table.remove(c.weights[i], best)
					end
					
					--normalize
					local sum = 0
					for d,s in ipairs(c.weights[i]) do
						sum = sum + s
					end
					if sum > 0 then
						for d,s in ipairs(c.weights[i]) do
							c.weights[i][d] = s / sum
						end
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
			obj.materials[name] = material
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
				
				--translation table
				local translate = {
					["VERTEX"] = "vertices",
					["NORMAL"] = "normals",
					["TEXCOORD"] = "texCoords",
					["COLOR"] = "colors",
					["TEXTANGENT"] = "tangents",
					["TANGENT"] = "tangents",
				}
				
				local stride = {
					["VERTEX"] = 3,
					["NORMAL"] = 3,
					["TEXCOORD"] = 2,
					["COLOR"] = 4,
					["COLOR"] = 4,
					["TEXTANGENT"] = 3,
					["TANGENT"] = 3,
				}
				
				--load all the buffers
				local inputs, vcount, matId
				if mesh.triangles then
					inputs = loadInputs(mesh.triangles[1], stride)
					matId = mesh.triangles[1]._attr.material
				elseif mesh.polylist then
					inputs, vcount = loadInputs(mesh.polylist[1], stride)
					matId = mesh.polylist[1]._attr.material
				elseif mesh.polygons then
					local idxs = { }
					vcount = { }
					matId = mesh.polygons[1]._attr.material
					
					--combine polygons
					for _,p in ipairs(mesh.polygons.p) do
						local a = loadFloatArray(p[1])
						for _,v in ipairs(a) do
							table.insert(idxs, v)
						end
						table.insert(vcount, #a)
					end
					
					inputs = loadInputs(mesh.polygons[1], stride, idxs)
				end
				
				--create mesh
				local mat = materials[matId]
				local material = self.materialLibrary[mat.name] or mat or obj.materials.None
				local m = self:newMesh(geometry._attr.id, material, obj.args.meshType)
				meshData[id] = m
				
				--flip UV
				for _,array in pairs(inputs["TEXCOORD"] or {}) do
					for i,v in ipairs(array) do
						array[i] = {v[1], 1.0 - v[2]}
					end
				end
				
				--insert values
				for from, to in pairs(translate) do
					for set, array in pairs(inputs[from] or { }) do
						m[set == 1 and to or (to .. set)] = array
					end
				end
				
				--construct faces
				local i = 1
				for face = 1, mesh.triangles and mesh.triangles[1]._attr.count or #vcount do
					local verts = mesh.triangles and 3 or vcount[i]
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
	
	local function skeletonLoader(nodes, parentTransform)
		local skel = { }
		for d,s in ipairs(nodes) do
			if s._attr.type == "JOINT" then
				local name = s._attr.name or s._attr.id
				
				--todo make common transformation getter
				local m = mat4(loadFloatArray(s.matrix[1][1]))
				local bindTransform = parentTransform and parentTransform * m or m
				
				skel[name] = {
					name = name,
					bindTransform = m,
					inverseBindTransform = bindTransform:invert(),
				}
				
				if s.node then
					skel[name].children = skeletonLoader(s.node, bindTransform)
				end
			end
		end
		return skel
	end
	
	--travers the scene graph
	local function loadNodes(nodes)
		for _,s in ipairs(nodes) do
			local name = s._attr.name or s._attr.id
			--todo
			local transform = mat4(loadFloatArray(s.matrix[1][1]))
			if s.instance_geometry then
				--object
				local id = s.instance_geometry[1]._attr.url:sub(2)
				local mesh = meshData[id]
				obj.meshes[name] = mesh:clone()
				obj.meshes[name]:setName(name)
				obj.meshes[name].transform = transform
			elseif s.instance_controller then
				--object associated with skeleton
				local id = s.instance_controller[1]._attr.url:sub(2)
				local controller = controllers[id]
				local mesh = meshData[controller.mesh]
				
				obj.meshes[name] = mesh:clone()
				obj.meshes[name]:setName(name)
				obj.meshes[name].transform = transform
				obj.meshes[name].weight = controller.weight
				obj.meshes[name].joints = controller.joints
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
					obj.skeleton = skeletonLoader(s.node)
				end
			end
			
			--children
			if s.node and s._attr.type ~= "JOINT" then
				loadNodes(s.node)
			end
		end
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
				for i = 1, #sources.OUTPUT / 16 do
					local m = mat4(unpack(sources.OUTPUT, i*16-15, i*16))
					table.insert(animation.frames, {
						time = sources.INPUT[i],
						rotation = quat.fromMatrix(m:subm()),
						position = vec3(m[4], m[8], m[12]),
					})
					animation.length = sources.INPUT[#sources.INPUT]
				end
			end
		end
		
		if #animation.frames > 0 then
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