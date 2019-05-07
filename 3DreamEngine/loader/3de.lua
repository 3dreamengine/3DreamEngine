--[[
#3de - object property file (3DreamEngine specific)
--]]

_3DreamEngine.loader["3de"] = function(self, obj, name, path)
	local mat
	for l in (love.filesystem.getInfo(self.objectDir .. name .. ".3de") and love.filesystem.lines(self.objectDir .. name .. ".3de") or love.filesystem.lines(name .. ".3de")) do
		if l:sub(1, 1) ~= "#" then
			local v = self:split(l, " ")
			if v[1] == "mat" then
				mat = obj.materials[l:sub(5)]
				assert(mat, name .. ".3de, no material named " .. l:sub(5))
			elseif v[1] == "new" then
				if v[2] == "particleSystem" then
					mat.particleSystems = mat.particleSystems or { }
					mat.particleSystems[#mat.particleSystems+1] = {objects = { }, randomSize = {0.75, 1.25}, randomRotation = true, normal = 1.0}
				end
			elseif v[1] == "add" then
				local o = self:loadObject(path .. "/" .. v[2], false, false, false, true)
				for d,s in pairs(o.objects) do
					table.insert(mat.particleSystems[#mat.particleSystems].objects, {object = s, amount = tonumber(v[3]) or 10})
				end
			elseif v[1] == "shader" then
				mat.particleSystems[#mat.particleSystems].shader = v[2]
			elseif v[1] == "shaderInfo" then
				mat.particleSystems[#mat.particleSystems].shaderInfo = v[2]
			elseif v[1] == "randomSize" then
				mat.particleSystems[#mat.particleSystems].randomSize = {tonumber(v[2]), tonumber(v[3])}
			elseif v[1] == "randomRotation" then
				mat.particleSystems[#mat.particleSystems].randomRotation = v[2] == "true"
			elseif v[1] == "randomDistance" then
				mat.particleSystems[#mat.particleSystems].randomDistance = tonumber(v[2]) or 0.0
			elseif v[1] == "normal" then
				mat.particleSystems[#mat.particleSystems].normal = tonumber(v[2])
			end
		end
	end
end