--[[
#obj - Wavefront OBJ file
--]]

_3DreamEngine.loader["obj"] = function(self, obj, name, path)
	--store vertices, normals and texture coordinates
	local vertices = { }
	local normals = { }
	local texVertices = { }
	
	--load object
	local material = obj.materials.None
	local blocked = false
	local o = obj.objects.default
	for l in (love.filesystem.getInfo(self.objectDir .. name .. ".obj") and love.filesystem.lines(self.objectDir .. name .. ".obj") or love.filesystem.lines(name .. ".obj")) do
		local v = self:split(l, " ")
		if not blocked then
			if v[1] == "v" then
				vertices[#vertices+1] = {tonumber(v[2]), tonumber(v[3]), -tonumber(v[4])}
			elseif v[1] == "vn" then
				normals[#normals+1] = {tonumber(v[2]), tonumber(v[3]), -tonumber(v[4])}
			elseif v[1] == "vt" then
				texVertices[#texVertices+1] = {tonumber(v[2]), 1-tonumber(v[3])}
			elseif v[1] == "usemtl" then
				material = obj.materials[l:sub(8)] or obj.materials.None
				if obj.splitMaterials and not obj.rasterMargin then
					local name = o.name .. "_" .. l:sub(8)
					obj.objects[name] = obj.objects[name] or {
						faces = { },
						final = { },
						name = o.name,
						material = material,
					}
					o = obj.objects[name]
				end
			elseif v[1] == "f" then
				if obj.rasterMargin then
					--split object, where 0|0|0 is the left-front-lower corner of the first object and every splitMargin is a new object with size 1.
					--So each object must be within -margin to splitMargin-margin, a perfect cube will be 0|0|0 to 1|1|1
					local objSize = 1
					local margin = (obj.rasterMargin-objSize)/2
					local v2 = self:split(v[2], "/")
					local x, y, z = vertices[tonumber(v2[1])][1], vertices[tonumber(v2[1])][2], vertices[tonumber(v2[1])][3]
					local tx, ty, tz = math.floor((x+margin)/obj.rasterMargin)+1, math.floor((z+margin)/obj.rasterMargin)+1, math.floor((-y-margin)/obj.rasterMargin)+2
					if not obj.objects[tx] then obj.objects[tx] = { } end
					if not obj.objects[tx][ty] then obj.objects[tx][ty] = { } end
					if not obj.objects[tx][ty][tz] then obj.objects[tx][ty][tz] = {faces = { }, final = { }, material = material} end
					o = obj.objects[tx][ty][tz]
					o.tx = math.floor((x+margin)/obj.rasterMargin)*obj.rasterMargin + objSize/2
					o.ty = math.floor((y+margin)/obj.rasterMargin)*obj.rasterMargin + objSize/2
					o.tz = math.floor((z+margin)/obj.rasterMargin)*obj.rasterMargin + objSize/2
					--print(tx, ty, tz, "|" .. x, y, z, "|" .. x - o.tx, y - o.ty, z - o.tz)
				end
				
				--link material to object, used as draw order identifier
				o.material = material
				
				--combine vertex and data into one
				for i = 1, #v-1 do
					local v2 = self:split(v[i+1]:gsub("//", "/0/"), "/")
					o.final[#o.final+1] = {vertices[tonumber(v2[1])], texVertices[tonumber(v2[2])] or {0, 0}, normals[tonumber(v2[3])], material}
				end
				
				if #v-1 == 3 then
					--tris
					o.faces[#o.faces+1] = {#o.final-0, #o.final-1, #o.final-2}
				elseif #v-1 == 4 then
					--quad
					o.faces[#o.faces+1] = {#o.final-1, #o.final-2, #o.final-3}
					o.faces[#o.faces+1] = {#o.final-0, #o.final-1, #o.final-3}
				else
					error("only tris and quads supported (got " .. (#v-1) .. " vertices)")
				end
			elseif v[1] == "o" then
				local name = l:sub(3)
				obj.objects[name] = obj.objects[name] or {
					faces = { },
					final = { },
					name = l:sub(3),
					material = material,
				}
				o = obj.objects[name]
			end
		end
		
		--skip objects named as frame when splitMargin is enabled (frames are used as helper objects)
		if v[1] == "o" and splitMargin then
			if l:find("frame") then
				blocked = true
			else
				blocked = false
			end
		end
	end
end