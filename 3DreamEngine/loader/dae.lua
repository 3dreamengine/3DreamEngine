--[[
#dae - COLLADA
--]]

local function loadFloatArray(arr)
	local t = { }
	for w in arr:gmatch("%S+") do
		t[#t+1] = tonumber(w)
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

return function(self, obj, path)
	local xml2lua = require(self.root .. "/libs/xml2lua/xml2lua")
	local handler = require(self.root .. "/libs/xml2lua/tree"):new()
	handler.options.noreduce = {
		["geometry"] = true,
		["animation"] = true,
		["controller"] = true,
		["source"] = true,
		["input"] = true,
		["node"] = true,
	}
	
	--load file
	local file = love.filesystem.read(path)
	
	--parse
	xml2lua.parser(handler):parse(file)
	
	local correction = mat4:getRotateX(-math.pi/2)
	
	local root = handler.root.COLLADA
	local geometry = root.library_geometries.geometry
	
	--load armatures and vertex weights
	local armatures = { }
	if root.library_controllers then
		for d,s in ipairs(root.library_controllers.controller) do
			if s._attr.name == "Armature" then
				local name = s.skin._attr.source:sub(2)
				local a = {
					bindPoses = { }, --unused?
					weights = { },
					joints = { },
					jointIDs = { },
				}
				armatures[name] = a
				
				--load sources
				local weights = { }
				for i,v in pairs(s.skin.source) do
					local typ = v.technique_common.accessor.param._attr.name
					if typ == "JOINT" then
						a.jointIDs = loadArray(v.Name_array[1])
					elseif typ == "TRANSFORM" then
						local t = loadFloatArray(v.float_array[1])
						for i = 1, #t / 16 do
							a.bindPoses[i] = mat4(unpack(t, i*16-15, i*16))
						end
					elseif typ == "WEIGHT" then
						weights = loadFloatArray(v.float_array[1])
					end
				end
				
				--load weights
				local vw = s.skin.vertex_weights
				local vcount = vw.vcount and loadFloatArray(vw.vcount) or { }
				local ids = loadFloatArray(vw.v)
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
	
	
	--load main geometry
	for d,s in ipairs(geometry) do
		local o = self:newSubObject(s._attr.id, obj, self:newMaterial())
		obj.objects[o.name] = o
		
		--parse sources
		local sources = { }
		for i,v in pairs(s.mesh.source) do
			local t = loadFloatArray(v.float_array[1])
			sources[v._attr.id] = t
		end
		if s.mesh.vertices then
			sources[s.mesh.vertices._attr.id] = sources[s.mesh.vertices.input[1]._attr.source:sub(2)]
		end
		
		--translation table
		local translate = {
			["VERTEX"] = "vertices",
			["NORMAL"] = "normals",
			["TEXCOORD"] = "texCoords",
			["COLOR"] = "colors",
		}
		
		--parse vertices
		local list = s.mesh.triangles or s.mesh.polylist
		
		--ids of source components per vertex
		local ids = loadFloatArray(list.p)
		
		--expand armature to all vertices
		if armatures[o.name] then
			o.weights = { }
			o.joints = { }
			o.jointIDs = armatures[o.name].jointIDs
		end
		
		local fields = #list.input
		for d,s in ipairs(list.input) do
			local f = translate[s._attr.semantic]
			if f then
				for i = 1, #ids / fields do
					local id = ids[(i-1)*fields + tonumber(s._attr.offset) + 1]
					local s = sources[s._attr.source:sub(2)]
					if f == "texCoords" then
						--xy vector
						o[f][i] = {
							s[id*2+1],
							s[id*2+2],
						}
					elseif f == "colors" then
						--rgba vector
						o[f][i] = {
							s[id*4+1],
							s[id*4+2],
							s[id*4+3],
							s[id*4+4],
						}
					else
						--xyz vectors
						o[f][i] = correction * vec3(
							s[id*3+1],
							s[id*3+2],
							s[id*3+3]
						)
						
						--also connect weight and joints
						if f == "vertices" and o.weights then
							o.weights[i] = armatures[o.name].weights[id+1]
							o.joints[i] = armatures[o.name].joints[id+1]
						end
					end
				end
			end
		end
		
		--vertex count per polygon
		local vcount = list.vcount and loadFloatArray(list.vcount) or { }
		
		--parse polygons
		local count = list._attr.count
		local i = 1
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
	end
	
	--load skeleton
	local rootJoint
	for d,s in ipairs(root.library_visual_scenes.visual_scene.node) do
		obj.joints = { }
		if s._attr.name == "Armature" then
			local function skeletonLoader(nodes, parentTransform)
				local skel = { }
				for d,s in ipairs(nodes) do
					if s._attr.type == "JOINT" then
						local name = s._attr.id
						
						local m = mat4(loadFloatArray(s.matrix[1]))
						if not parentTransform then
							m = correction * m
							rootJoint = name
						end
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
		local function loadAnimation(anim)
			local animations = { }
			for _,a in ipairs(anim) do
				if a.animation then
					animations[a._attr.id] = loadAnimation(a.animation)
				else
					local keyframes = { }
					local name = a.channel._attr.target:sub(1, -11)
					
					--parse sources
					local sources = { }
					for d,s in ipairs(a.source) do
						sources[s._attr.id] = s.float_array and loadFloatArray(s.float_array[1]) or s.Name_array and loadArray(s.Name_array[1])
					end
					for d,s in ipairs(a.sampler.input) do
						sources[s._attr.semantic] = sources[s._attr.source:sub(2)]
					end
					
					--get matrices
					local frames = { }
					local positions = { }
					for i = 1, #sources.OUTPUT / 16 do
						local m = mat4(unpack(sources.OUTPUT, i*16-15, i*16))
						if name == rootJoint then
							m = correction * m
						end
						frames[#frames+1] = {
							time = sources.INPUT[i],
							interpolations = sources.INTERPOLATION[i],
							rotation = quat.fromMatrix(m:subm()),
							position = vec3(m[4], m[8], m[12]),
						}
					end
					
					--pack
					animations[a._attr.id] = {
						frames = frames,
						joint = name,
					}
				end
			end
			return animations
		end
		obj.animations = loadAnimation(root.library_animations.animation)
	end
end