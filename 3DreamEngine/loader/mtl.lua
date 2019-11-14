--[[
#mtl - Material Library File for .obj
--]]

_3DreamEngine.loader["mtl"] = function(self, obj, path)
	--materials
	local material = obj.materials.None
	for l in love.filesystem.lines(path) do
		local v = self:split(l, " ")
		if v[1] == "newmtl" then
			obj.materials[l:sub(8)] = {
				color = {1.0, 1.0, 1.0, 1.0},
				specular = 0.5,
				name = l:sub(8),
				ID = #obj.materialsID+1,
			}
			obj.materialsID[#obj.materialsID+1] = obj.materials[l:sub(8)]
			material = obj.materials[l:sub(8)]
		elseif v[1] == "Ks" then
			material.specular = tonumber(v[2])
		elseif v[1] == "Kd" then
			local r, g, b = tonumber(v[2]), tonumber(v[3]), tonumber(v[4])
			
			if obj.desaturate then
				local ch, cs, cb = self.RGBtoHSV(r, g, b)
				r, g, b = self.HSVtoRGB(ch, cs * 0.85, cb^0.6)
			end
			
			material.color[1] = r
			material.color[2] = g
			material.color[3] = b
		elseif v[1] == "d" then
			material.color[4] = tonumber(v[2])
		elseif v[1] == "reflections" then
			material.reflections = v[2] ~= "false"
		elseif v[1] == "shaderInfo" then
			material.shaderInfo = v[2]
		elseif v[1] == "shader" then
			material.shader = v[2]
		elseif v[1] == "alphaThreshold" then
			material.alphaThreshold = tonumber(v[2])
		elseif v[1] == "emission" then
			material.emission = tonumber(v[2])
		elseif v[1] == "map_Kd" then
			material.tex_diffuse = obj.dir .. "/" .. (l:sub(8):match("(.+)%..+") or l:sub(8))
		elseif v[1] == "map_Ks" then
			material.tex_specular = obj.dir .. "/" .. (l:sub(8):match("(.+)%..+") or l:sub(8))
		elseif v[1] == "map_Kn" then
			material.tex_normal = obj.dir .. "/" .. (l:sub(8):match("(.+)%..+") or l:sub(8))
		elseif v[1] == "map_Ke" then
			material.tex_emission = obj.dir .. "/" .. (l:sub(8):match("(.+)%..+") or l:sub(8))
		end
	end
end