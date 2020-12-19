--[[
#dae - COLLADA
--]]

--load space seperated arrays as floats or as strings
local function loadFloatArray(arr)
	local t = { }
	for w in arr:gmatch("%S+") do
		t[#t+1] = tonumber(w)
	end
	return t
end

local function loadVecArray(arr, stride)
	local t = { }
	for w in arr:gmatch("%S+") do
		if #t == 0 or #t[#t] >= stride then
			t[#t+1] = { }
		end
		table.insert(t[#t], tonumber(w))
	end
	return t
end

local function loadArray(arr)
	local t = { }
	for w in arr:gmatch("%S+") do
		t[#t+1] = w
	end
	return t
end

--load entire tree and index all IDs
local indices
local localToGlobal
local function indexTree(node)
	for key,child in pairs(node) do
		if type(child) == "table" and key ~= "_attr" then
			indexTree(child)
		end
	end
	
	if node._attr and node._attr.id then
		indices[node._attr.id] = node
		indices["#" .. node._attr.id] = node
		
		if node._attr.sid then
			localToGlobal[node._attr.sid] = node._attr.id
		end
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
	localToGlobal = { }
	indexTree(root)
	
	
	--load armatures and vertex weights
	local armatures = { }
	local controllers = { }
	if root.library_controllers then
		for d,s in ipairs(root.library_controllers[1].controller) do
			if s.skin then
				local name = s.skin[1]._attr.source:sub(2)
				local a = {
					weights = { },
					joints = { },
					jointIDs = { },
				}
				armatures[name] = a
				controllers[s._attr.id] = name
				
				--load sources
				local weights = { }
				for i,v in ipairs(s.skin[1].source) do
					local typ = v.technique_common[1].accessor[1].param[1]._attr.name
					if typ == "JOINT" then
						a.jointIDs = loadArray(v.Name_array[1][1])
						for d,s in ipairs(a.jointIDs) do
							a.jointIDs[d] = localToGlobal[s] or s
						end
					elseif typ == "WEIGHT" then
						weights = loadFloatArray(v.float_array[1][1])
					end
				end
				
				--load weights
				local vw = s.skin[1].vertex_weights[1]
				local vcount = vw.vcount and loadFloatArray(vw.vcount[1][1]) or { }
				local ids = loadFloatArray(vw.v[1][1])
				local count = tonumber(vw._attr.count)
				local fields = #vw.input
				for _,input in ipairs(vw.input) do
					local typ = input._attr.semantic
					local offset = 1 + tonumber(input._attr.offset)
					if typ == "JOINT" then
						local ci = 1
						for i = 1, count do
							local verts = vcount[i] or 1
							a.joints[i] = { }
							for v = 1, verts do
								local id = ids[(ci-1)*fields+offset]
								a.joints[i][v] = id+1
								ci = ci + 1
							end
						end
					elseif typ == "WEIGHT" then
						local ci = 1
						for i = 1, count do
							local verts = vcount[i] or 1
							a.weights[i] = { }
							for v = 1, verts do
								local id = ids[(ci-1)*fields+offset]
								a.weights[i][v] = weights[id+1]
								ci = ci + 1
							end
						end
					end
				end
				
				--normalize weights and limit to 4 (GPU limit)
				for i = 1, #a.weights do
					while #a.weights[i] > 4 do
						local min, best = math.huge, 1
						for d,s in ipairs(a.weights[i]) do
							if s < min then
								min = s
								best = d
							end
						end
						table.remove(a.joints[i], best)
						table.remove(a.weights[i], best)
					end
					
					--normalize
					local sum = 0
					for d,s in ipairs(a.weights[i]) do
						sum = sum + s
					end
					if sum > 0 then
						for d,s in ipairs(a.weights[i]) do
							a.weights[i][d] = s / sum
						end
					end
				end
			end
		end
	end
	
	
	--load materials
	if root.library_materials then
		for _,mat in ipairs(root.library_materials[1].material) do
			local name = mat._attr.name
			local material = self:newMaterial(name)
			obj.materials[name] = material
			indices[mat._attr.id] = material
			
			--load
			if mat.instance_effect then
				local effect = indices[mat.instance_effect[1]._attr.url]
				
				--get first profile
				local profile
				for d,s in pairs(effect) do
					profile = s[1]
				end
				
				--parse data
				if profile then
					for step, dataArr in pairs(profile.technique[1]) do
						if step ~= "_attr" then
							local data = dataArr[1]
							if data.emission then
								local e = data.emission[1]
								if e.color then
									local color = loadFloatArray( e.color[1][1] )
									material.emission = {color[1] * color[4], color[2] * color[4], color[3] * color[4]}
								end
							end
							if data.diffuse then
								local d = data.diffuse[1]
								if d.color then
									local color = loadFloatArray( d.color[1][1] )
									material.color = color
								end
							end
							if data.specular then
								local s = data.specular[1]
								if s.color then
									local color = loadFloatArray( s.color[1][1] )
									material.specular = math.sqrt(color[1]^2 + color[2]^2 + color[3]^2)
								end
							end
							if data.shininess then
								material.glossiness = tonumber( data.shininess[1].float[1][1] )
							end
							if data.index_of_refraction then
								material.ior = tonumber( data.index_of_refraction[1].float[1][1] )
							end
						end
					end
				end
			end
		end
	end
	
	
	--load main geometry
	local meshData = { }
	for d,geo in ipairs(root.library_geometries[1].geometry) do
		local mesh = geo.mesh[1]
		local id = geo._attr.id
		meshData[id] = meshData[id] or { }
		
		--translation table
		local translate = {
			["VERTEX"] = "vertices",
			["NORMAL"] = "normals",
			["TEXCOORD"] = "texCoords",
			["COLOR"] = "colors",
		}
		
		local stride = {
			["VERTEX"] = 3,
			["NORMAL"] = 3,
			["TEXCOORD"] = 2,
			["COLOR"] = 4,
		}
		
		--parse vertices
		local o
		local lastMaterial
		local index = 0
		local edges = { }
		for typ = 1, 3 do
			local list
			if typ == 1 then
				list = mesh.triangles
			elseif typ == 2 then
				list = mesh.polylist
			else
				list = mesh.polygons
			end
			if list then
				for _,l in ipairs(list) do
					local mat = indices[l._attr.material] or obj.materials.None
					local material = self.materialLibrary[mat.name] or mat
					if not o then
						o = self:newSubObject(geo._attr.id, obj, material)
						meshData[id][#meshData[id]+1] = o
					end
					
					--connect with armature
					if armatures[o.name] and not o.weights then
						o.weights = { }
						o.joints = { }
						o.jointIDs = armatures[o.name].jointIDs
					end
					
					--ids of source components per vertex
					local ids
					local vcount
					if typ == 3 then
						ids = { }
						vcount = { }
						
						--combine polygons
						for _,p in ipairs(l.p) do
							local a = loadFloatArray(p[1])
							for _,v in ipairs(a) do
								ids[#ids+1] = v
							end
							vcount[#vcount+1] = #a
						end
					else
						ids = loadFloatArray(l.p[1][1])
						vcount = l.vcount and loadFloatArray(l.vcount[1][1]) or { }
					end
					
					--get max offset
					local fields = 0
					for d,input in ipairs(l.input) do
						fields = tonumber(input._attr.offset) + 1
					end
					
					--parse data arrays
					for d,input in ipairs(l.input) do
						local f = translate[input._attr.semantic]
						if f then
							--fetch data from the mesh source or from a nested vertice data block
							local otherInput = indices[input._attr.source].input
							local data = (otherInput and indices[otherInput[1]._attr.source] or indices[input._attr.source]).float_array[1][1]
							local s = loadVecArray(data, stride[input._attr.semantic])
							
							--flip UV
							if f == "texCoords" then
								for i,v in ipairs(s) do
									s[i] = {v[1], 1.0 - v[2]}
								end
							end
							
							--parse
							for i = 1, #ids / fields do
								local id = ids[(i-1)*fields + tonumber(input._attr.offset) + 1] + 1
								
								--connect data
								o[f][index+i] = s[id]
								
								--also connect weight and joints
								if f == "vertices" then
									if o.weights then
										o.weights[index+i] = armatures[o.name].weights[id]
										o.joints[index+i] = armatures[o.name].joints[id]
									end
									o.materials[index+i] = material
								end
							end
						end
					end
					
					--parse polygons
					local count = l._attr.count
					local i = index+1
					for face = 1, count do
						local verts = vcount[face] or 3
						
						if verts == 3 then
							--tris
							o.faces[#o.faces+1] = {i, i+1, i+2}
						else
							--triangulates, fan style
							for f = 1, verts-2 do
								o.faces[#o.faces+1] = {i, i+f, i+f+1}
							end
						end
						i = i + verts
					end
					
					index = #o.vertices
				end
			end
		end
	end
	
	
	--load light
	local lightIDs = { }
	if root.library_lights then
		for d,light in ipairs(root.library_lights[1].light) do
			local l = self:newLight()
			lightIDs[light._attr.id] = l
			
			if light.extra and light.extra[1] and light.extra[1].technique and light.extra[1].technique[1] then
				local dat = light.extra[1].technique[1]
				
				l:setColor(dat.red and tonumber(dat.red[1][1]) or 1.0, dat.green and tonumber(dat.green[1][1]) or 1.0, dat.blue and tonumber(dat.blue[1][1]) or 1.0)
				l:setBrightness(dat.energy and tonumber(dat.energy[1][1]) or 1.0)
			end
			
			table.insert(obj.lights, l)
		end
	end
	
	--connect meshdata and instance and add it as object
	local function addObject(name, mesh, transform)
		for _,subObject in ipairs(meshData[mesh]) do
			local id = name
			obj.objects[id] = subObject:clone()
			obj.objects[id]:setName(name)
			obj.objects[id].transform = correction * transform
		end
	end
	
	
	--load scene
	for d,s in ipairs(root.library_visual_scenes[1].visual_scene[1].node) do
		obj.joints = { }
		if s.instance_geometry then
			--object
			local id = s.instance_geometry[1]._attr.url:sub(2)
			local name = s._attr.name or s._attr.id
			local transform = mat4(loadFloatArray(s.matrix[1][1]))
			addObject(name, id, transform)
		elseif s.instance_light then
			local transform = correction * mat4(loadFloatArray(s.matrix[1][1]))
			local l = lightIDs[s.instance_light[1]._attr.url:sub(2)]
			l:setPosition(transform[4], transform[8], transform[12])
		elseif s._attr.name == "Armature" then
			--propably an armature
			--TODO: not a proper way to identify armature nodes
			local function skeletonLoader(nodes, parentTransform)
				local skel = { }
				for d,s in ipairs(nodes) do
					if s.instance_controller then
						--object associated with skeleton
						local id = s.instance_controller[1]._attr.url:sub(2)
						local mesh = controllers[id]
						local name = s._attr.name or s._attr.id
						local transform = mat4(loadFloatArray(s.matrix[1][1]))
						addObject(name, mesh, transform)
					end
					if s._attr.type == "JOINT" then
						local name = s._attr.id
						
						local m = mat4(loadFloatArray(s.matrix[1][1]))
						local bindTransform = parentTransform and parentTransform * m or m
						
						skel[name] = {
							name = name,
							bindTransform = m,
							inverseBindTransform = bindTransform:invert(),
						}
						
						obj.joints[name] = skel[name]
						if s.node then
							skel[name].children = skeletonLoader(s.node, bindTransform)
						end
					end
				end
				return skel
			end
			obj.skeleton = skeletonLoader(s.node)
			break
		end
	end
	
	
	--load animations
	if root.library_animations then
		local animations = { }
		local function loadAnimation(anim)
			for _,a in ipairs(anim) do
				if a.animation then
					loadAnimation(a.animation)
				else
					local keyframes = { }
					local name = a.channel[1]._attr.target:sub(1, -11)
					
					--parse sources
					local sources = { }
					for d,s in ipairs(a.source) do
						sources[s._attr.id] = s.float_array and loadFloatArray(s.float_array[1][1]) or s.Name_array and loadArray(s.Name_array[1][1])
					end
					for d,s in ipairs(a.sampler[1].input) do
						sources[s._attr.semantic] = sources[s._attr.source:sub(2)]
					end
					
					--get matrices
					local frames = { }
					local positions = { }
					for i = 1, #sources.OUTPUT / 16 do
						local m = mat4(unpack(sources.OUTPUT, i*16-15, i*16))
						frames[#frames+1] = {
							time = sources.INPUT[i],
							--interpolation = sources.INTERPOLATION[i],
							rotation = quat.fromMatrix(m:subm()),
							position = vec3(m[4], m[8], m[12]),
						}
					end
					
					--pack
					animations[name] = frames
				end
			end
		end
		loadAnimation(root.library_animations[1].animation)
		
		--split animations
		if obj.args.animations then
			obj.animations = { }
			obj.animationLengths = { }
			for anim, time in pairs(obj.args.animations) do
				obj.animations[anim] = { }
				obj.animationLengths[anim] = time[2] - time[1]
				for joint, frames in pairs(animations) do
					local newFrames = { }
					for i, frame in ipairs(frames) do
						if frame.time >= time[1] and frame.time <= time[2] then
							table.insert(newFrames, frame)
						end
					end
					obj.animations[anim][joint] = newFrames
				end
			end
		else
			obj.animations = {
				default = animations,
			}
			obj.animationLengths = {
				default = animations[#animations].time,
			}
		end
	end
end