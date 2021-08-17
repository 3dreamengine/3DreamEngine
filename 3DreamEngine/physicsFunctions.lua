--[[
#part of the 3DreamEngine by Luke100000
physicsFunctions.lua - contains physics library relevant functions
--]]

local lib = _3DreamEngine

local physicsLowerMode = "full"

function lib:setPhysicsLowerMode(m)
	assert(m == "complex" or m == m == "full" or m == "simple" or m == "height", "lower mode has to be complex, full, simple or height")
	physicsLowerMode = m
end
function lib:getPhysicsLowerMode()
	return physicsLowerMode
end

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

--preprocess mesh and link required data
function lib:getPhysicsData(obj)
	local p = { }
	p.groups = self:groupVertices(obj.faces, obj.vertices)
	p.vertices = obj.vertices
	p.normals = obj.normals
	p.transform = obj.transform or mat4.getIdentity()
	p.name = obj.name
	return p
end

local threshold = 1 / 0.01
local function insert(v, g)
	local vx = math.floor(v.x * threshold)
	local vz = math.floor(v.z * threshold)
	if not g[vx] then
		g[vx] = { }
	end
	if not g[vx][vz] then
		g[vx][vz] = {math.huge, -math.huge}
	end
	g[vx][vz][1] = math.min(g[vx][vz][1], v.y)
	g[vx][vz][2] = math.max(g[vx][vz][2], v.y)
end

--get most likely vertex to reconstruct order
local function smallest(x, y, x1, y1, x2, y2, x3, y3)
	local d1 = math.abs(x1 - x) + math.abs(y1 - y)
	local d2 = math.abs(x2 - x) + math.abs(y2 - y)
	local d3 = math.abs(x3 - x) + math.abs(y3 - y)
	local min = math.min(d1, d2, d3)
	return d1 == min and 1 or d2 == min and 2 or 3
end

function lib:getPhysicsObject(phy)
	local n = { }
	
	n.typ = "mesh"
	n.name = phy.name
	n.objects = { }
	n.normals = { }
	n.highest = { }
	n.lowest = { }
	
	--transform vertices
	lib.deltonLoad:start("transform")
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
	lib.deltonLoad:stop()
	
	local bothSides = physicsLowerMode == "complex" or physicsLowerMode == "full"
	local normalThreshold = 0.01
	
	for group, faces in ipairs(phy.groups) do
		--create vertex group for faster access
		lib.deltonLoad:start("height")
		local g = { }
		local verts_top = { }
		local verts_bottom = { }
		local sides = { }
		local lowest = math.huge
		for faceID,face in ipairs(faces) do
			--store all vertices in a threshold sized 2D grid for fast lookups
			local a = vertices[face[1]]
			local b = vertices[face[2]]
			local c = vertices[face[3]]
			insert(a, g)
			insert(b, g)
			insert(c, g)
			
			--wether it is a top faced triangle or not
			local n = (b-a):cross(c-a):normalize().y
			
			--remember lowest for simple lower mode
			lowest = math.min(lowest, a.y, b.y, c.y)
			
			--add either to the top or bottom list, instead of remembering the side for each vertex
			if n > normalThreshold then
				verts_top[face[1]] = a
				verts_top[face[2]] = b
				verts_top[face[3]] = c
				sides[faceID] = true
			elseif bothSides and n < -normalThreshold then
				verts_bottom[face[1]] = a
				verts_bottom[face[2]] = b
				verts_bottom[face[3]] = c
				sides[faceID] = false
			end
		end
		
		local opposite = { }
		for side = 1, 2 do
			for d,s in pairs(side == 1 and verts_top or verts_bottom) do
				if physicsLowerMode == "height" then
					opposite[d] = -math.huge
				elseif physicsLowerMode == "simple" then
					opposite[d] = lowest
				end
				
				--find the bottom most vertex
				if not opposite[d] then
					lib.deltonLoad:start("find")
					for x = math.floor(s.x * threshold - 0.5), math.floor(s.x * threshold + 0.5) do
						if g[x] then
							for z = math.floor(s.z * threshold - 0.5), math.floor(s.z * threshold + 0.5) do
								if g[x][z] then
									if side == 1 then
										opposite[d] = math.min(opposite[d] or s.y, g[x][z][1])
									else
										opposite[d] = math.max(opposite[d] or s.y, g[x][z][2])
									end
								end
							end
						end
					end
					lib.deltonLoad:stop()
				end
				
				--no real opposite vertex found, interpolate and retriangulate opposite face
				if math.abs(opposite[d] - s.y) == 0 then
					if physicsLowerMode == "complex" then
						lib.deltonLoad:start("interpolate")
						local g = phy.groups[group]
						for faceID, face in ipairs(g) do
							--vertices
							local a = vertices[face[1]]
							local b = vertices[face[2]]
							local c = vertices[face[3]]
							
							local w1, w2, w3 = self:getBarycentric(s.x, s.z, a.x, a.z, b.x, b.z, c.x, c.z)
							local inside = w1 >= 0 and w2 >= 0 and w3 >= 0 and w1 <= 1 and w2 <= 1 and w3 <= 1
							if inside then
								local h = a.y * w1 + b.y * w2 + c.y * w3
								
								if side == 1 and h < s.y or side == 2 and h > s.y then
									opposite[d] = h
									goto done
								end
							end
						end
						::done::
						lib.deltonLoad:stop()
					else
						opposite[d] = lowest
					end
				end
			end
		end
		lib.deltonLoad:stop()
		
		--create polygons
		lib.deltonLoad:start("triangles")
		local cache = { }
		for faceID,face in ipairs(faces) do
			--verify
			local side = sides[faceID]
			if side ~= nil then
				--vertices
				local a = vertices[face[1]]
				local b = vertices[face[2]]
				local c = vertices[face[3]]
				
				--create physics shape
				local ok, shape = pcall(love.physics.newPolygonShape, a.x, a.z, b.x, b.z, c.x, c.z)
				
				if ok then
					--reconstruct the order, since the polygon might have restructured itself
					local x1, y1, x2, y2, x3, y3 = shape:getPoints()
					local translation = {
						[smallest(a.x, a.z, x1, y1, x2, y2, x3, y3)] = face[1],
						[smallest(b.x, b.z, x1, y1, x2, y2, x3, y3)] = face[2],
						[smallest(c.x, c.z, x1, y1, x2, y2, x3, y3)] = face[3],
					}
					
					--avoid duplicates
					local ID = math.floor(math.min(a.x, b.x, c.x) * 1000)
					local center = a + b + c
					for i = ID-1, ID+1 do
						if cache[i] then
							for _,c in pairs(cache[i]) do
								if (center.x - c.x)^2 + (center.z - c.z)^2 < 1 / 1000 then
									ID = nil
									break
								end
							end
						end
					end
					
					if ID then
						cache[ID] = cache[ID] or { }
						table.insert(cache[ID], center)
						
						--add shape
						table.insert(n.objects, shape)
						
						--face normal
						table.insert(n.normals, {
							normals[translation[1]] * (side and 1 or -1),
							normals[translation[2]] * (side and 1 or -1),
							normals[translation[3]] * (side and 1 or -1),
						})
						
						--triangle height
						table.insert(n[side and "highest" or "lowest"], {
							vertices[translation[1]].y,
							vertices[translation[2]].y,
							vertices[translation[3]].y,
						})
						
						--triangle lowest
						table.insert(n[side and "lowest" or "highest"], {
							opposite[translation[1]],
							opposite[translation[2]],
							opposite[translation[3]],
						})
					end
				end
			end
		end
		lib.deltonLoad:stop()
	end
	
	return n
end