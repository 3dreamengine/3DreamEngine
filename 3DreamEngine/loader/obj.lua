--[[
#obj - Wavefront OBJ file
--]]

return function(self, obj, path, loadAsCollisions)
	--store vertices, normals and texture coordinates
	local vertices = { }
	local normals = { }
	local texture = { }
	
	--load object
	local material = obj.materials.None
	
	local o_col = self:newSubObject("COLLISION_object", obj, material)
	obj.objects.COLLISION_object = o_col
	
	local o_def = self:newSubObject("object", obj, material)
	obj.objects.object = o_def
	
	local o = loadAsCollisions and o_col or o_def
	
	for l in love.filesystem.lines(path) do
		local v = self:split(l, " ")
		
		if v[1] == "v" then
			vertices[#vertices+1] = {tonumber(v[2]), tonumber(v[3]), tonumber(v[4])}
		elseif v[1] == "vn" then
			normals[#normals+1] = {tonumber(v[2]), tonumber(v[3]), tonumber(v[4])}
		elseif v[1] == "vt" then
			texture[#texture+1] = {tonumber(v[2]), 1.0 - tonumber(v[3])}
		elseif v[1] == "usemtl" then
			material = obj.materials[l:sub(8)] or self.materialLibrary[l:sub(8)] or obj.materials.None
			
			--if required, start a new object
			if obj.splitMaterials and not o.name:find("COLLISION") and not loadAsCollisions then
				local name = o.name .. "_" .. l:sub(8)
				obj.objects[name] = obj.objects[name] or self:newSubObject(o.name, obj, material)
				o = obj.objects[name]
			else
				o.material = material
			end
		elseif v[1] == "f" then
			local verts = #v-1
			
			--combine vertex and data into one
			for i = 1, verts do
				local v2 = self:split(v[i+1]:gsub("//", "/0/"), "/")
				
				local index = #o.vertices+1
				o.vertices[index] = vertices[tonumber(v2[1])]
				o.texCoords[index] = texture[tonumber(v2[2])]
				if not loadAsCollisions then
					o.normals[index] = normals[tonumber(v2[3])]
					o.materials[index] = material
					o.extras[index] = material.shaderValue or o.shaderValue or 1.0
				end
			end
			
			local index = #o.vertices
			if verts == 3 then
				--tris
				o.faces[#o.faces+1] = {index-2, index-1, index}
			else
				--triangulates, fan style
				for i = 1, verts-2 do
					o.faces[#o.faces+1] = {index-verts+1, index-verts+1+i, index-verts+2+i}
				end
			end
		elseif v[1] == "o" then
			local name = self:decodeObjectName(l:sub(3))
			if obj.mergeObjects then
				--only split collision data
				o = name:find("COLLISION") and o_col or o_def
			else
				if loadAsCollisions then
					name = "COLLISION_" .. name
				end
				
				obj.objects[name] = obj.objects[name] or self:newSubObject(name, obj, material)
				o = obj.objects[name]
			end
		end
	end
end