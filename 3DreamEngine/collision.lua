--[[
#part of the 3DreamEngine by Luke100000
#see init.lua for license and documentation
collision.lua - loads .obj files as collision object(s) and handles per-point collisions of cuboids in any rotation
--]]

local lib = _3DreamEngine

function lib.loadCollObject(self, name)
	--store vertices
	local vertices = { }
	local faces = { }
	
	--split up
	for l in (love.filesystem.getInfo(self.objectDir .. name .. ".obj") and love.filesystem.lines(self.objectDir .. name .. ".obj") or love.filesystem.lines(name .. ".obj")) do
		local v = self:split(l, " ")
		if not blocked then
			if v[1] == "v" then
				vertices[#vertices+1] = {tonumber(v[2]), tonumber(v[3]), -tonumber(v[4])}
			elseif v[1] == "f" then
				--combine vertex and data into one
				faces[#faces+1] = { }
				for i = 1, #v-1 do
					local v2 = self:split(v[i+1]:gsub("//", "/0/"), "/")
					faces[#faces][#faces[#faces]+1] = vertices[tonumber(v2[1])]
				end
			end
		end
	end
	
	function link(s)
		for d,f in ipairs(faces) do
			local found = false
			for i,v in ipairs(f) do
				if v == s then
					found = true
				end
			end
			
			if found then
				for i,v in ipairs(f) do
					if not v[4] then
						v[4] = s[4]
						link(v)
					end
				end
			end
		end
	end
	
	--split objects
	local last = 0
	for d,s in ipairs(vertices) do
		if not s[4] then
			last = last + 1
			s[4] = last
			link(s)
		end
	end
	local objects = { }
	for d,s in ipairs(vertices) do
		objects[s[4]] = objects[s[4]] or { }
		table.insert(objects[s[4]], s)
	end
	
	local obj = {
		name = name,
		objects = { },
	}
	
	--create collision objects
	for d,s in ipairs(objects) do
		local origin = s[1]
		for _,v in ipairs(s) do
			if v[1]+v[2]+v[3] < origin[1]+origin[2]+origin[3] then
				origin = v
			end
		end
		
		--get 3 vertices from the origin
		local axisR = { }
		for d,f in ipairs(faces) do
			local found = false
			for i,v in ipairs(f) do
				if v == origin then
					found = i
				end
			end
			
			if found then
				local f1 = f[(found-1-1)%#f+1]
				local f2 = f[(found+1-1)%#f+1]
				
				axisR[f1] = math.sqrt((f1[1]-origin[1])^2 + (f1[2]-origin[2])^2 + (f1[3]-origin[3])^2)
				axisR[f2] = math.sqrt((f2[1]-origin[1])^2 + (f2[2]-origin[2])^2 + (f2[3]-origin[3])^2)
			end
		end
		
		local axis = { }
		for d,s in pairs(axisR) do
			axis[#axis+1] = d
		end
		
		if #axis == 3 then
			--dimensions
			print(axisR[axis[1]])
			print(axisR[axis[2]])
			print(axisR[axis[3]])
			print()
			
			--choose the axis with the highest X value as the normal vector, (1, 0, 0) therefore means no rotation
			local n = {0, 0, 0}
			for s = 1, 3 do
				local v = (axis[1][s] - origin[s]) / axisR[axis[1]]
				n[s] = v
			end
			print("n", n[1], n[2], n[3])
			
			local rotX = math.acos(n[3] / math.sqrt(n[3]^2 + n[2]^2))
			n[2] = self:rotatePoint(n[2], math.sqrt(1-n[2]^2), -rotX)
			n[3] = self:rotatePoint(n[3], math.sqrt(1-n[3]^2), -rotX)
			print("n", n[1], n[2], n[3])
			
			local rotY = math.acos(n[1] / math.sqrt(n[1]^2 + n[3]^2))
			n[1] = self:rotatePoint(n[1], math.sqrt(1-n[1]^2), -rotY)
			n[3] = self:rotatePoint(n[3], math.sqrt(1-n[3]^2), -rotY)
			print("n", n[1], n[2], n[3])
			
			local rotZ = math.acos(n[2] / math.sqrt(n[2]^2 + n[2]^2))
			n[1] = self:rotatePoint(n[1], math.sqrt(1-n[1]^2), -rotZ)
			n[2] = self:rotatePoint(n[2], math.sqrt(1-n[2]^2), -rotZ)
			print("n", n[1], n[2], n[3])
			
			print(rotX, rotY, rotZ)
		else
			print("object " .. name .. " contains objects which are no cubes with exactly 8 vertices, 6 4-poly faces")
		end
	end
	
	return obj
end