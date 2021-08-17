--[[
#obj - Wavefront OBJ file
--]]

return function(self, obj, path)
	--store vertices, normals and texture coordinates
	local vertices = { }
	local normals = { }
	local texture = { }
	
	--load object
	local material = obj.materials.None
	
	local o = self:newMesh("object", obj, material)
	obj.objects.object = o
	objectID = "object"
	
	for l in love.filesystem.lines(path) do
		local v = string.split(l, " ")
		
		if v[1] == "v" then
			vertices[#vertices+1] = {tonumber(v[2]), tonumber(v[3]), tonumber(v[4])}
		elseif v[1] == "vn" then
			normals[#normals+1] = {tonumber(v[2]), tonumber(v[3]), tonumber(v[4])}
		elseif v[1] == "vt" then
			texture[#texture+1] = {tonumber(v[2]), 1.0 - tonumber(v[3])}
		elseif v[1] == "usemtl" then
			material = self.materialLibrary[l:sub(8)] or obj.materials[l:sub(8)] or obj.materials.None
			o.material = material
		elseif v[1] == "f" then
			local verts = #v-1
			
			--combine vertex and data into one
			local index = #o.vertices
			for i = 1, verts do
				local v2 = string.split(v[i+1]:gsub("//", "/0/"), "/")
				index = index + 1
				o.vertices[index] = vertices[tonumber(v2[1])]
				o.texCoords[index] = texture[tonumber(v2[2])]
				o.normals[index] = normals[tonumber(v2[3])]
				o.materials[index] = material
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
			objectID = self:decodeObjectName(l:sub(3))
			obj.objects[objectID] = obj.objects[objectID] or self:newMesh(objectID, obj, material)
			o = obj.objects[objectID]
		end
	end
end