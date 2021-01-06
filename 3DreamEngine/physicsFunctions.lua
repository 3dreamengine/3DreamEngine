--[[
#part of the 3DreamEngine by Luke100000
physicsFunctions.lua - contains physics library relevant functions
--]]

local lib = _3DreamEngine

--receives an array of faces defined by three indices and an array with vertices and returns an array of connected subsets and an array of subset vertices indices
--connected sets are defined by a single shared vertex, recognized by its reference
function lib:groupVertices(faces, vertices)
	--initilize group indices
	local groupIndices = { }
	for d,s in ipairs(vertices) do
		groupIndices[s] = d
	end
	
	--group vertices
	local active
	local found = true
	while found do
		found = false
		active = { }
		for _,s in ipairs(faces) do
			local a = vertices[s[1]]
			local b = vertices[s[2]]
			local c = vertices[s[3]]
			
			local ga = groupIndices[a]
			local gb = groupIndices[b]
			local gc = groupIndices[c]
			
			local min = math.min(ga, gb, gc)
			local max = math.max(ga, gb, gc)
			
			if min == max then
				active[ga] = true
			else
				groupIndices[a] = min
				groupIndices[b] = min
				groupIndices[c] = min
				found = true
			end
		end
	end
	
	--split into groups
	local groups = { }
	local ID = 0
	for group,_ in pairs(active) do
		ID = ID + 1
		groups[ID] = { }
		for _,s in ipairs(faces) do
			local a = vertices[s[1]]
			if groupIndices[a] == group then
				table.insert(groups[ID], s)
			end
		end
	end
	
	return groups
end

--preprocess subObject and link required data
function lib:getPhysicsData(obj)
	local p = { }
	p.groups = self:groupVertices(obj.faces, obj.vertices)
	p.vertices = obj.vertices
	p.normals = obj.normals
	p.transform = obj.transform or mat4.getIdentity()
	p.name = obj.name
	return p
end

function lib:getPhysicsObject(phy)
	local n = { }
	
	n.typ = "triangle"
	n.objects = { }
	n.normals = { }
	n.highest = { }
	n.lowest = { }
	
	local groups = phy.groups
	
	--transform vertices
	local transformed = { }
	local vertices = { }
	for d,s in ipairs(phy.vertices) do
		if not transformed[s] then
			transformed[s] = phy.transform * vec3(s)
		end
		vertices[d] = transformed[s]
	end
	
	--transform normals
	local transformed = { }
	local normals = { }
	local subm = phy.transform:subm()
	for d,s in ipairs(phy.normals) do
		if not transformed[s] then
			transformed[s] = subm * vec3(s)
		end
		normals[d] = transformed[s]
	end
	
	--create vertex group for faster access
	local vertexGroups = { }
	for group, faces in ipairs(groups) do
		local g = { }
		for _,face in ipairs(faces) do
			g[face[1]] = vertices[face[1]]
			g[face[2]] = vertices[face[2]]
			g[face[3]] = vertices[face[3]]
		end
		vertexGroups[group] = g
	end
	
	--look for highest and lowest value, or triangulate the face it is in
	local lowest = { }
	local threshold = 0.01
	for group, gv in ipairs(vertexGroups) do
		for d,s in pairs(gv) do
			for i,v in pairs(gv) do
				if v.y < s.y then
					local dist = (s.x-v.x)^2 + (s.z-v.z)^2
					if dist < threshold then
						lowest[d] = v.y
						break
					end
				end
			end
			
			--no opposite vertex found, interpolate and retriangulate opposite face
			if not lowest[d] then
				local g = groups[group]
				for faceID, face in ipairs(g) do
					--vertices
					local a = vertices[face[1]]
					local b = vertices[face[2]]
					local c = vertices[face[3]]
					
					local w1, w2, w3 = self:getBarycentric(s.x, s.z, a.x, a.z, b.x, b.z, c.x, c.z)
					local inside = w1 >= 0 and w2 >= 0 and w3 >= 0 and w1 <= 1 and w2 <= 1 and w3 <= 1
					if inside then
						local h = a.y * w1 + b.y * w2 + c.y * w3
						
						if h < s.y then
							lowest[d] = h
							goto done
						end
					end
				end
				::done::
			end
			
			--corner
			if not lowest[d] then
				lowest[d] = s.y
			end
		end
	end
	
	--get most likely vertex to reconstruct order
	local function smallest(x, y, x1, y1, x2, y2, x3, y3)
		local d1 = math.abs(x1 - x) + math.abs(y1 - y)
		local d2 = math.abs(x2 - x) + math.abs(y2 - y)
		local d3 = math.abs(x3 - x) + math.abs(y3 - y)
		local min = math.min(d1, d2, d3)
		return d1 == min and 1 or d2 == min and 2 or 3
	end
	
	--create polygons
	for gID,group in ipairs(groups) do
		for _,face in ipairs(group) do
			--vertices
			local a = vertices[face[1]]
			local b = vertices[face[2]]
			local c = vertices[face[3]]
			
			local normal = (b-a):cross(c-a):normalize()
			
			--verify
			if normal.y > 0 then
				local ok, shape = pcall(love.physics.newPolygonShape, a.x, a.z, b.x, b.z, c.x, c.z)
				
				if ok then
					--reconstruct the order, since the polygon might have restructured itself
					local x1, y1, x2, y2, x3, y3 = shape:getPoints()
					local translation = {
						face[smallest(a.x, a.z, x1, y1, x2, y2, x3, y3)],
						face[smallest(b.x, b.z, x1, y1, x2, y2, x3, y3)],
						face[smallest(c.x, c.z, x1, y1, x2, y2, x3, y3)],
					}
					
					--add shape
					table.insert(n.objects, shape)
					
					--face normal
					table.insert(n.normals, {
						normals[translation[1]],
						normals[translation[2]],
						normals[translation[3]],
					})
					
					--triangle height
					table.insert(n.highest, {
						vertices[translation[1]].y,
						vertices[translation[2]].y,
						vertices[translation[3]].y,
					})
					
					--triangle lowest
					table.insert(n.lowest, {
						lowest[translation[1]],
						lowest[translation[2]],
						lowest[translation[3]],
					})
				end
			end
		end
	end
	
	return n
end