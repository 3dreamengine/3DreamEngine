--[[
#mat - 3Dream material file
extends an existing .mtl file but is designed to work alone
3Dream material files have the same structure as in memory but have the name as a field instead of index
--]]

return function(self, obj, path)
	local materials = love.filesystem.load(path)()
	for _,s in ipairs(materials[1] and materials or {materials}) do
		local name = s.name or "material"
		
		--create new material if necessary
		if not obj.materials[name] then
			obj.materials[name] = self:newMaterial(name)
		end
		
		--extend/overwrite material
		local mat = obj.materials[name]
		for i,v in pairs(s) do
			mat[i] = v
		end
	end
end