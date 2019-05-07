--[[
#mtl - Material Library File for .obj
--]]

_3DreamEngine.loader["mtl"] = function(self, obj, name, path)
	--materials
	local material = obj.materials.None
	for l in (love.filesystem.getInfo(self.objectDir .. name .. ".mtl") and love.filesystem.lines(self.objectDir .. name .. ".mtl") or love.filesystem.lines(name .. ".mtl")) do
		local v = self:split(l, " ")
		if v[1] == "newmtl" then
			obj.materials[l:sub(8)] = {
				color = {1.0, 1.0, 1.0, 1.0},
				specular = 0.5,
				name = l:sub(8),
			}
			material = obj.materials[l:sub(8)]
		elseif v[1] == "Ks" then
			material.specular = tonumber(v[2])
		elseif v[1] == "Kd" then
			material.color[1] = tonumber(v[2])
			material.color[2] = tonumber(v[3])
			material.color[3] = tonumber(v[4])
		elseif v[1] == "d" then
			material.color[4] = tonumber(v[2])
		elseif v[1] == "map_Kd" then
			material.tex_diffuse = self:loadTexture(l:sub(8), path)
		elseif v[1] == "map_Ks" then
			material.tex_spec = self:loadTexture(l:sub(8), path)
		elseif v[1] == "map_Kn" then
			material.tex_normal = self:loadTexture(l:sub(8), path)
		end
	end
end