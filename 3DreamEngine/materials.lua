--[[
#part of the 3DreamEngine by Luke100000
materials.lua - load and process materials
--]]

---@type Dream
local lib = _3DreamEngine

---Registers a material to the material library. Materials in loaded objects with the same name then use this one. Multiple registered aliases are valid.
---@param material DreamMaterial
---@param name string @ optional
function lib:registerMaterial(material, name)
	self.materialLibrary[name or material.name] = material
end

---Looks for mat files or directories with an albedo texture
function lib:loadMaterialLibrary(path, prefix)
	if path:sub(-1) == "/" then
		path = path:sub(1, -1)
	end
	
	prefix = prefix or ""
	
	if self:getImagePath(path .. "/albedo") then
		--directory is a basic material since it contains at least the albedo texture
		local mat = self:newMaterial(prefix .. (path:match(".*/(.*)") or path))
		mat.library = true
		mat:lookForTextures(path)
		mat.library = true
		self.materialLibrary[mat.name] = mat
	else
		for _, s in ipairs(love.filesystem.getDirectoryItems(path)) do
			local p = path .. "/" .. s
			local ext = s:sub(#s - 3)
			if ext == ".lua" then
				--custom material
				local mat = self:newMaterial((prefix .. s):sub(1, -5))
				mat:loadFromFile(p)
				mat.library = true
				mat:lookForTextures(path, mat.name)
				self.materialLibrary[mat.name] = mat
			elseif love.filesystem.getInfo(p .. "/material.lua") then
				--material using the recommended directory-format
				local mat = self:newMaterial(prefix .. s)
				mat:loadFromFile(p .. "/material.lua")
				mat.library = true
				mat:lookForTextures(p)
				self.materialLibrary[mat.name] = mat
			elseif love.filesystem.getInfo(p, "directory") then
				--directory is not a material, but maybe its child directories
				self:loadMaterialLibrary(p, prefix)
			end
		end
	end
end