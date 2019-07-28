--[[
#obj - Wavefront OBJ file
--]]

_3DreamEngine.loader["obj"] = function(self, obj, path, simple)
	--store vertices, normals and texture coordinates
	local vertices = { }
	local normals = { }
	local texVertices = { }
	
	--load object
	local material = obj.materials.None
	local blocked = false
	local o = obj.objects.default
	
	local t = love.timer.getTime()
	for l in love.filesystem.lines(path) do
		local v = self:split(l, " ")
		
		if v[1] == "o" then
			blocked = false
		end
		
		if v[1] == "v" then
			vertices[#vertices+1] = {tonumber(v[2]), tonumber(v[3]), -tonumber(v[4])}
		elseif v[1] == "vn" then
			normals[#normals+1] = {tonumber(v[2]), tonumber(v[3]), -tonumber(v[4])}
		elseif v[1] == "vt" then
			texVertices[#texVertices+1] = {tonumber(v[2]), 1-tonumber(v[3])}
		elseif v[1] == "usemtl" and not blocked then
			material = obj.materials[l:sub(8)] or obj.materials.None
			if obj.splitMaterials and not o.name:find("LAMP") then
				local nameBase = o.name .. "_" .. l:sub(8)
				local name = simple and (nameBase .. "_simple_" .. simple) or nameBase
				
				obj.objects[name] = obj.objects[name] or {
					faces = { },
					final = { },
					material = material,
					
					name = o.name, --using base objects name instead, because the material is irelevant as a name
					simple = simple,
					super = simple and (simple == 1 and nameBase or (nameBase .. "_simple_" .. (simple-1))) or nil,
					simpler = simple and (nameBase .. "_simple_" .. (simple+1)) or nil,
				}
				o = obj.objects[name]
			else
				o.material = material
			end
		elseif v[1] == "f" and not blocked then
			--combine vertex and data into one
			for i = 1, #v-1 do
				local v2 = self:split(v[i+1]:gsub("//", "/0/"), "/")
				
				local dv = vertices[tonumber(v2[1])]
				local dn = normals[tonumber(v2[3])]
				local uv = texVertices[tonumber(v2[2])] or {0, 0}
				
				o.final[#o.final+1] = {
					dv[1], dv[2], dv[3],    --position
					material.shaderInfo or o.shaderInfo or 1.0, --extra float for animations
					dn[1], dn[2], dn[3],    --normal
					material.ID,            --material
					uv[1], uv[2],           --UV
				}
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
		elseif v[1] == "o" and not blocked then
			if l:find("REMOVE") then
				blocked = true
			else
				local nameBase = self:decodeObjectName(l:sub(3))
				local name = simple and (nameBase .. "_simple_" .. simple) or nameBase
				
				obj.objects[name] = obj.objects[name] or {
					faces = { },
					final = { },
					material = material,
					
					name = nameBase,
					simple = simple,
					super = simple == 1 and nameBase or simple and (nameBase .. "_simple_" .. (simple-1)) or nil,
					simpler = simple and (nameBase .. "_simple_" .. (simple+1)) or nil
				}
				o = obj.objects[name]
			end
		end
	end
end