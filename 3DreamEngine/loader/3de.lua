--[[
#3de - object property file (3DreamEngine specific)
extends the material (in case of .obj the material defined in the .mtl file) with particle systems
--]]

_3DreamEngine.loader["3de"] = function(self, obj, name, path)
	local extended = love.filesystem.getInfo(self.objectDir .. name .. ".3de") and dofile(self.objectDir .. name .. ".3de") or dofile(name .. ".3de")
	
	for d,s in pairs(extended) do
		local mat = obj.materials[d]
		if mat then
			for i,v in pairs(s) do
				mat[i] = v
			end
			
			if s.particleSystems then
				for psID, ps in ipairs(s.particleSystems) do
					ps.objects_new = { }
					ps.randomSize = ps.randomSize or {0.75, 1.25}
					ps.normal = ps.normal or 1.0
					
					for i,v in pairs(ps.objects) do
						local o = self:loadObjectLazy(path .. "/" .. i, {cleanup = false, noMesh = true})
						while not o.loaded do
							o:resume()
							coroutine.yield()
						end
						for d,s in pairs(o.objects) do
							table.insert(ps.objects_new, {object = s, materials = o.materials, materialsID = o.materialsID, amount = v})
						end
					end
					ps.objects, ps.objects_new = ps.objects_new, ps.objects
				end
			end
		else
			error("can not extend material " .. d .. " (nil)")
		end
	end
end