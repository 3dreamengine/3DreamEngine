--[[
#obj - Wavefront OBJ file
--]]

return function(self, obj, path, loadAsCollisions)
	--store vertices, normals and texture coordinates
	local vertices = { }
	local normals = { }
	local texVertices = { }
	
	--load object
	local material = obj.materials.None
	local blocked = false
	
	obj.objects.COLLISION_object = obj.objects.COLLISION_object or {
		faces = { },
		final = { },
		material = material,
		name = "COLLISION_object",
	}
	local o_col = obj.objects.COLLISION_object
	
	obj.objects.object = obj.objects.object or {
		faces = { },
		final = { },
		material = material,
		name = "object",
	}
	local o_def = obj.objects.object
	
	local o = loadAsCollisions and o_col or o_def
	
	for l in love.filesystem.lines(path) do
		local v = self:split(l, " ")
		
		if v[1] == "o" then
			blocked = false
		end
		
		if v[1] == "v" then
			vertices[#vertices+1] = {tonumber(v[2]), tonumber(v[3]), tonumber(v[4])}
		elseif v[1] == "vn" then
			normals[#normals+1] = {tonumber(v[2]), tonumber(v[3]), tonumber(v[4])}
		elseif v[1] == "vt" then
			texVertices[#texVertices+1] = {tonumber(v[2]), 1.0 - tonumber(v[3])}
		elseif v[1] == "usemtl" and not blocked then
			material = obj.materials[l:sub(8)] or self.materialLibrary[l:sub(8)] or obj.materials.None
			if obj.splitMaterials and not o.name:find("COLLISION") and not loadAsCollisions then
				local name = o.name .. "_" .. l:sub(8)
				
				obj.objects[name] = obj.objects[name] or {
					faces = { },
					final = { },
					material = material,
					
					name = o.name, --using base objects name instead, because the material is irelevant as a name
				}
				o = obj.objects[name]
			else
				o.material = material
			end
		elseif v[1] == "f" and not blocked then
			local verts = #v-1
			
			--combine vertex and data into one
			for i = 1, verts do
				local v2 = self:split(v[i+1]:gsub("//", "/0/"), "/")
				
				local dv = vertices[tonumber(v2[1])]
				local dn = normals[tonumber(v2[3])]
				local uv = texVertices[tonumber(v2[2])]
				
				o.final[#o.final+1] = {
					dv[1], dv[2], dv[3],                             --position
					material.shaderValue or o.shaderValue or 1.0,    --extra float for animations
					dn[1], dn[2], dn[3],                             --normal
					material,                                        --material
					uv and uv[1], uv and uv[2],                      --UV
				}
			end
			
			if verts == 3 then
				--tris
				o.faces[#o.faces+1] = {#o.final-2, #o.final-1, #o.final-0}
			else
				--triangulates, fan style
				for i = 1, verts-2 do
					o.faces[#o.faces+1] = {#o.final-verts+1, #o.final-verts+1+i, #o.final-verts+2+i}
				end
			end
		elseif v[1] == "o" and not blocked then
			if l:find("REMOVE") then
				blocked = true
			elseif obj.mergeObjects then
				o = self:decodeObjectName(l:sub(3)):find("COLLISION") and o_col or o_def
			else
				local name = self:decodeObjectName(l:sub(3))
				
				if loadAsCollisions then
					name = "COLLISION_" .. name
				end
				
				obj.objects[name] = obj.objects[name] or {
					faces = { },
					final = { },
					material = material,
					
					name = name,
				}
				o = obj.objects[name]
			end
		end
	end
end