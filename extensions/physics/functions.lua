--[[
#part of the 3DreamEngine by Lukehuge000
physicsFunctions.lua - contains physics library relevant functions
--]]

local lib = _3DreamEngine

local gridResolution = 100
local function insert(v, g)
	local vx = math.floor(v.x * gridResolution)
	local vz = math.floor(v.z * gridResolution)
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

function lib:getMeshPhysicsObject(phy, transform)
	lib.deltonLoad:start("newPhysicsMesh")
	
	local n = { }
	
	n.typ = "mesh"
	n.name = phy.name
	n.objects = { }
	n.normals = { }
	n.highest = { }
	n.lowest = { }
	
	--transform vertices
	lib.deltonLoad:start("transform")
	local subm = transform:subm()
	local transformed = { }
	local vertices = { }
	local normals = { }
	for _,f in ipairs(phy.faces) do
		for i = 1, 3 do
			local d = f[i]
			local pos = phy.vertices[d]
			if not transformed[pos] then
				transformed[pos] = transform and transform * pos or pos
			end
			vertices[d] = transformed[pos]
			
			local normal = phy.normals[d]
			if not transformed[normal] then
				transformed[normal] = subm and subm * normal or normal
			end
			normals[d] = transformed[normal]
		end
	end
	
	local normals = phy.normals
	lib.deltonLoad:stop()
	
	local normalThreshold = 0.0001
	
	--todo math.huge cause mathematical problems, investogate
	local huge = 1000
	
	--create vertex group for faster access
	lib.deltonLoad:start("height")
	local grid = { }
	local verts_top = { }
	local verts_bottom = { }
	local sides = { }
	local lowest = math.huge
	
	for faceID, face in ipairs(phy.faces) do
		--store all vertices in a threshold sized 2D grid for fast lookups
		local a = vertices[face[1]]
		local b = vertices[face[2]]
		local c = vertices[face[3]]
		insert(a, grid)
		insert(b, grid)
		insert(c, grid)
		
		--whether it is a top faced triangle or not
		local n = (b-a):cross(c-a):normalize().y
		
		--remember lowest for simple lower mode
		lowest = math.min(lowest, a.y, b.y, c.y)
		
		--add either to the top or bottom list, instead of remembering the side for each vertex
		if n > normalThreshold then
			verts_top[face[1]] = a
			verts_top[face[2]] = b
			verts_top[face[3]] = c
			sides[faceID] = true
		elseif phy.shapeMode == "complex" and n < -normalThreshold then
			verts_bottom[face[1]] = a
			verts_bottom[face[2]] = b
			verts_bottom[face[3]] = c
			sides[faceID] = false
		end
	end
	
	local opposite = { }
	for side = 1, 2 do
		for i,verts in pairs(side == 1 and verts_top or verts_bottom) do
			if phy.shapeMode == "height" then
				opposite[i] = -huge
			elseif phy.shapeMode == "simple" then
				opposite[i] = lowest
			else
				--find the bottom most vertex
				if not opposite[i] then
					for x = math.floor(verts.x * gridResolution - 0.5), math.floor(verts.x * gridResolution + 0.5) do
						if grid[x] then
							for z = math.floor(verts.z * gridResolution - 0.5), math.floor(verts.z * gridResolution + 0.5) do
								if grid[x][z] then
									if side == 1 then
										opposite[i] = math.min(opposite[i] or verts.y, grid[x][z][1])
									else
										opposite[i] = math.max(opposite[i] or verts.y, grid[x][z][2])
									end
								end
							end
						end
					end
					
					--no real opposite vertex found, interpolate and retriangulate opposite face
					if math.abs(opposite[i] - verts.y) == 0 then
						for faceID, face in ipairs(phy.faces) do
							--vertices
							local a = vertices[face[1]]
							local b = vertices[face[2]]
							local c = vertices[face[3]]
							
							local w1, w2, w3 = self:getBarycentric(verts.x, verts.z, a.x, a.z, b.x, b.z, c.x, c.z)
							local inside = w1 >= 0 and w2 >= 0 and w3 >= 0 and w1 <= 1 and w2 <= 1 and w3 <= 1
							if inside then
								local h = a.y * w1 + b.y * w2 + c.y * w3
								
								if side == 1 and h < verts.y or side == 2 and h > verts.y then
									opposite[i] = h
									goto done
								end
							end
						end
						::done::
					end
					
					opposite[i] = opposite[i] or lowest
				end
			end
		end
	end
	lib.deltonLoad:stop()
	
	--create polygons
	lib.deltonLoad:start("triangles")
	local cache = { }
	for faceID,face in ipairs(phy.faces) do
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
					
					if phy.shapeMode == "wall" then
						--triangle height
						table.insert(n[side and "highest" or "lowest"], {
							side and huge or -huge,
							side and huge or -huge,
							side and huge or -huge,
						})
						
						--triangle lowest
						table.insert(n[side and "lowest" or "highest"], {
							side and -huge or huge,
							side and -huge or huge,
							side and -huge or huge,
						})
					else
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
	end
	lib.deltonLoad:stop()
	
	lib.deltonLoad:stop()
	
	return n
end