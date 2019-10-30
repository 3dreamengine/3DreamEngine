--[[
#3de - 3Dream material file (3DreamEngine specific)
extends the material (in case of .obj the material defined in the .mtl file) with particle systems
--]]

_3DreamEngine.loader["3de"] = function(self, obj, path)
	local extended = love.filesystem.load(path)()
	for d,s in pairs(extended) do
		--create new material if necessary
		if not obj.materials[d] then
			obj.materials[d] = {
				color = {1.0, 1.0, 1.0, 1.0},
				specular = 0.5,
				name = d,
				ID = #obj.materialsID+1,
			}
			obj.materialsID[#obj.materialsID+1] = obj.materials[d]
		end
		
		--extend/overwrite material
		local mat = obj.materials[d]
		for i,v in pairs(s) do
			mat[i] = v
		end
		
		--load objects of particle system
		if s.particleSystems then
			for psID, ps in ipairs(s.particleSystems) do
				ps.objects_new = { }
				ps.randomSize = ps.randomSize or {0.75, 1.25}
				ps.normal = ps.normal or 1.0
				
				for i,v in pairs(ps.objects) do
					local o = self:loadObject(obj.dir .. "/" .. i, {noCleanup = true, noMesh = true})
					for d,s in pairs(o.objects) do
						table.insert(ps.objects_new, {object = s, materials = o.materials, materialsID = o.materialsID, amount = v})
					end
				end
				ps.objects, ps.objects_new = ps.objects_new, ps.objects
			end
		end
	end
end