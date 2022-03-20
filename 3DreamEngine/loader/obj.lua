--[[
#obj - Wavefront OBJ file
--]]

return function(self, obj, path)
	--store vertices, normals and texture coordinates
	local vertices = { }
	local normals = { }
	local texture = { }
	
	--initial mesh
	local material = self:newMaterial()
	local mesh = self:newMesh("object", material)
	local meshID = "object"
	obj.meshes[meshID] = mesh
	
	for l in love.filesystem.lines(path) do
		local v = string.split(l, " ")
		
		if v[1] == "v" then
			table.insert(vertices, {tonumber(v[2]), tonumber(v[3]), tonumber(v[4])})
		elseif v[1] == "vn" then
			table.insert(normals, {tonumber(v[2]), tonumber(v[3]), tonumber(v[4])})
		elseif v[1] == "vt" then
			table.insert(texture, {tonumber(v[2]), 1.0 - tonumber(v[3])})
		elseif v[1] == "usemtl" then
			material = self.materialLibrary[l:sub(8)]
			if not material then
				if not obj.args.ignoreMissingMaterials then
					print("material " .. l:sub(8) .. " is unknown")
				end
				material = self:newMaterial()
			end
			mesh.material = material
		elseif v[1] == "f" then
			local verts = #v-1
			
			--combine vertex and data into one
			local index = #mesh.vertices
			for i = 1, verts do
				local v2 = string.split(v[i+1]:gsub("//", "/0/"), "/")
				index = index + 1
				mesh.vertices[index] = vertices[tonumber(v2[1])]
				mesh.texCoords[index] = texture[tonumber(v2[2])]
				mesh.normals[index] = normals[tonumber(v2[3])]
			end
			
			local index = #mesh.vertices
			if verts == 3 then
				--tris
				table.insert(mesh.faces, {index-2, index-1, index})
			else
				--triangulates, fan style
				for i = 1, verts-2 do
					table.insert(mesh.faces, {index-verts+1, index-verts+1+i, index-verts+2+i})
				end
			end
		elseif v[1] == "o" then
			if obj.args.decodeBlenderNames then
				meshID = string.match(l:sub(3), "(.*)_.*") or l:sub(3)
			else
				meshID = l:sub(3)
			end
			obj.meshes[meshID] = obj.meshes[meshID] or self:newMesh(meshID, material)
			mesh = obj.meshes[meshID]
		end
	end
end