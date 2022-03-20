--[[
#part of the 3DreamEngine by Luke100000
materials.lua - load and process materials
--]]

local lib = _3DreamEngine

function lib:registerMaterial(material, name)
	name = name or material.name
	if material.registeredAs then
		error("This material already have been registered with the name '" .. material.registeredAs .. "', clone it first.")
	end
	material.name = name
	material.registeredAs = name
	self.materialLibrary[name] = material
end

--looks for mat files or directories with an albedo texture
function lib:loadMaterialLibrary(path, prefix)
	if path:sub(-1) == "/" then
		path = path:sub(1, -1)
	end
	
	prefix = prefix or ""
	
	if self:getImagePath(path .. "/albedo") then
		--directory is a basic material since it contains at least the albedo texture
		local mat = self:newMaterial(prefix .. (path:match(".*/(.*)") or path))
		mat.library = true
		self:lookForTextures(mat, path)
		mat.library = true
		self.materialLibrary[mat.name] = mat
		return
	end
	
	for d,s in ipairs(love.filesystem.getDirectoryItems(path)) do
		local p = path .. "/" .. s
		if s:sub(#s - 3) == ".mat" then
			--custom material
			local mat = self:newMaterial((prefix .. s):sub(1, -5))
			local matLoaded = love.filesystem.load(p)()
			table.merge(mat, matLoaded)
			mat.mat = matLoaded
			mat.library = true
			self:lookForTextures(mat, path, mat.name)
			self.materialLibrary[mat.name] = mat
		elseif love.filesystem.getInfo(p .. "/material.mat") then
			--material using the recommended directory-format
			local mat = self:newMaterial(prefix .. s)
			local matLoaded = love.filesystem.load(p .. "/material.mat")()
			table.merge(mat, matLoaded)
			mat.mat = matLoaded
			mat.library = true
			self:lookForTextures(mat, p)
			self.materialLibrary[mat.name] = mat
		elseif love.filesystem.getInfo(p, "directory") then
			--directory is not a material, but maybe its child directories
			self:loadMaterialLibrary(p, prefix)
		end
	end
end

--link textures to material
local function texSetter(mat, typ, tex)
	--use the setter function to overwrite color
	local func = "set" .. typ:sub(1, 1):upper() .. typ:sub(2) .. "Texture"
	if mat[func] then
		mat[func](mat, tex)
	else
		mat[typ .. "Texture"] = tex
	end
end

function lib:lookForTextures(mat, directory, filter)
	for _,typ in ipairs({"albedo", "normal", "roughness", "metallic", "emission", "ao", "material"}) do
		local custom = mat[typ .. "Texture"]
		mat[typ .. "Texture"] = nil
		
		if type(custom) == "userdata" then
			--already an image
			texSetter(mat, typ, custom)
		elseif type(custom) == "string" then
			--path or name specified
			local path = self:getImagePath(custom) or
				self:getImagePath(directory .. "/" .. custom) or
				(love.filesystem.getInfo(custom, "file")) and custom or
				(love.filesystem.getInfo(directory .. "/" .. custom, "file")) and (directory .. "/" .. custom)
			
			if path then
				texSetter(mat, typ, path)
			end
		elseif self:getImagePath(directory .. "/" .. typ) then
			--recommending file naming is used
			texSetter(mat, typ, self:getImagePath(directory .. "/" .. typ))
		else
			--let's look for possible matches
			for name, path in pairs(lib:getImagePaths()) do
				if name:sub(1, #directory) == directory then
					local fn = name:sub(#directory + 2):lower()
					if fn:find(typ) and (not filter or fn:find(filter:lower())) then
						texSetter(mat, typ, path)
						break
					end
				end
			end
		end
	end
	
	--combiner
	if not mat["materialTexture"] then
		if mat["metallicTexture"] or mat["roughnessTexture"] or mat["aoTex"] then
			mat["materialTexture"] = self:combineTextures(mat["roughnessTexture"], mat["metallicTexture"], mat["aoTex"])
		end
	end
	
	--convert shader id to actual shader object
	mat.pixelShader = lib:getShader(mat.pixelShader)
	mat.vertexShader = lib:getShader(mat.vertexShader)
	mat.worldShader = lib:getShader(mat.worldShader)
	
	mat.mat = nil
end