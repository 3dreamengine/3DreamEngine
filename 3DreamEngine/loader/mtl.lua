--[[
#mtl - Material Library File for .obj
--]]

return function(self, obj, path)
	--materials
	local material = obj.materials.None
	for l in love.filesystem.lines(path) do
		local v = self:split(l, " ")
		if v[1] == "newmtl" then
			obj.materials[l:sub(8)] = self:newMaterial(l:sub(8))
			material = obj.materials[l:sub(8)]
		elseif v[1] == "Ks" then -- specular color
			local r, g, b = tonumber(v[2]), tonumber(v[3]), tonumber(v[4])
			local v = math.sqrt(r^2+g^2+b^2) / math.sqrt(3)
			material.specular = v
		elseif v[1] == "Ns" then -- specular exponent
			material.glossiness = tonumber(v[2]) / 1000
		elseif v[1] == "Kd" then -- diffuse
			local r, g, b = tonumber(v[2]), tonumber(v[3]), tonumber(v[4])
			
			if obj.desaturate then
				local ch, cs, cb = self:RGBtoHSV(r, g, b)
				r, g, b = self:HSVtoRGB(ch, cs * 0.85, cb^0.6)
			end
			
			material.color[1] = r
			material.color[2] = g
			material.color[3] = b
		elseif v[1] == "d" then
			material.color[4] = tonumber(v[2])
		elseif v[1] == "Tr" then
			material.color[4] = 1.0 - tonumber(v[2])
		elseif v[1] == "ior" then
			material.ior = tonumber(v[2])
		elseif v[1] == "shaderValue" then
			material.shaderValue = v[2]
		elseif v[1] == "shader" then
			material.shader = v[2]
		elseif v[1] == "cullMode" then
			material.cullMode = v[2]
		elseif v[1] == "emission" then
			material.emission = {tonumber(v[2]), tonumber(v[3]) or tonumber(v[2]), tonumber(v[4]) or tonumber(v[2])}
		elseif v[1] == "roughness" then
			material.roughness = tonumber(v[2])
		elseif v[1] == "metallic" then
			material.metallic = tonumber(v[2])
		elseif v[1] == "reflections" then
			material.reflections = tonumber(v[2]) or 0.0
		elseif v[1] == "map_Ka" or v[1] == "map_Kd" then
			material.tex_albedo = obj.dir .. "/" .. (l:sub(8):match("(.+)%..+") or l:sub(8))
		elseif v[1] == "map_Kr" or v[1] == "map_Ks" then
			material.tex_roughness = obj.dir .. "/" .. (l:sub(8):match("(.+)%..+") or l:sub(8))
		elseif v[1] == "map_Km" then
			material.tex_metallic = obj.dir .. "/" .. (l:sub(8):match("(.+)%..+") or l:sub(8))
		elseif v[1] == "map_Kn" then
			material.tex_normal = obj.dir .. "/" .. (l:sub(8):match("(.+)%..+") or l:sub(8))
		elseif v[1] == "map_Ke" then
			material.tex_emission = obj.dir .. "/" .. (l:sub(8):match("(.+)%..+") or l:sub(8))
		elseif v[1] == "illum" then
			
		end
	end
end