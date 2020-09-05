--[[
#part of the 3DreamEngine by Luke100000
materials.lua - load and process materials
--]]

local lib = _3DreamEngine

--creates an empty material
function lib.newMaterial(self, name, dir)
	return {
		color = {0.5, 0.5, 0.5, 1.0}, --base color
		glossiness = 0.1,             --used for vertex color based shader
		specular = 0.5,               --used for vertex color based shader
		emission = false,             --used vertex color based shader
		alpha = false,                --decides on what pass it will go
		name = name or "None",        --name, used for texture linking
		dir = dir,                    --directory, used for texture linking
		obj = false,                  --object to which the material is assigned to. If it is false, it is most likely a public material from the material library.
		ior = 1.0,                    --used for second pass refractions, should be used on full-object glass like diamonds only, else it might reflect itself, which is incorrect
	}
end

--recognise mat files and directories with an albedo texture or "material.mat" as materials
--if the material is a directory it will skip the structured texture linking and uses the string.find to support extern material libraries
function lib.loadMaterialLibrary(self, path, prefix)
	prefix = prefix or ""
	for d,s in ipairs(love.filesystem.getDirectoryItems(path)) do
		local p = path .. "/" .. s
		
		if s:sub(#s-4) == ".mat" then
			--found material file
			local dummyObj = {materials = { }, dir = path}
			self.loader["mat"](self, dummyObj, p)
			
			--insert to material library
			for i,v in pairs(dummyObj.materials) do
				v.dir = path
				self:finishMaterial(v)
				self.materialLibrary[prefix .. i] = v
			end
		elseif love.filesystem.getInfo(p .. "/material.mat") then
			--directory is a material since it contains an anonymous material file (not nested, directly returns material without name)
			local dummyObj = {materials = { }, dir = p}
			self.loader["mat"](self, dummyObj, p .. "/material.mat", true)
			
			local mat = dummyObj.materials.material
			mat.dir = p
			self:finishMaterial(mat)
			self.materialLibrary[prefix .. s] = mat
		elseif self.imageDirectories[p] then
			--directory is a material since it contains at least one texture
			local mat = self:newMaterial(s, p)
			self:finishMaterial(mat)
			self.materialLibrary[prefix .. s] = mat
		elseif love.filesystem.getInfo(p, "directory") then
			--directory is not a material, but maybe its child directories
			self:loadMaterialLibrary(p, prefix .. s .. "/")
		end
	end
end

--link textures to material
function lib:finishMaterial(mat, obj)
	setmetatable(mat, self.meta.material)
	
	for _,typ in ipairs({"albedo", "normal", "roughness", "metallic", "emission", "ao", "specular", "glossiness"}) do
		local custom = mat["tex_" .. typ]
		mat["tex_" .. typ] = nil
		if custom then
			if type(custom) == "userdata" then
				mat["tex_" .. typ] = custom
			else
				--path specified
				custom = custom and custom:match("(.+)%..+") or custom
				for _,p in pairs({
					custom,
					(mat.dir and (mat.dir .. "/") or "") .. custom,
				}) do
					if self.images[p] then
						mat["tex_" .. typ] = self.images[p]
						break
					end
				end
			end
		elseif not obj then
			--skip matching, just look for files in same directory
			--this is a material library entry
			local images = self.imageDirectories[mat.dir]
			if images then
				for i,v in pairs(images) do
					if string.find(i, typ) then
						mat["tex_" .. typ] = v
						break
					end
				end
			end
		else
			--search for correctly named texture in the material directory
			local dir = mat.dir and (mat.dir .. "/") or ""
			for _,p in pairs({
				dir .. typ,                               -- e.g. "materialDirectory/albedo.png"
				dir .. mat.name .. "/" .. typ,            -- e.g. "materialDirectory/materialName/albedo.png"
				dir .. mat.name .. "_" .. typ,            -- e.g. "materialDirectory/materialName_albedo.png"
				dir .. obj.name .. "_" .. typ,      	  -- e.g. "materialDirectory/objectName_albedo.png"
			}) do
				if self.images[p] then
					mat["tex_" .. typ] = self.images[p]
					break
				end
			end
		end
	end
	
	if not mat["tex_" .. "combined"] then
		local metallicRoughness = mat["tex_metallic"] or mat["tex_roughness"]
		local specularGlossiness = mat["tex_specular"] or mat["tex_glossiness"]
		
		if metallicRoughness or specularGlossiness or mat["tex_ao"] then
			if metallicRoughness then
				mat["tex_" .. "combined"] = self:combineTextures(mat["tex_roughness"], mat["tex_metallic"], mat["tex_ao"])
			elseif specularGlossiness then
				mat["tex_" .. "combined"] = self:combineTextures(mat["tex_glossiness"], mat["tex_specular"], mat["tex_ao"])
			end
		end
	end
	
	if mat.onFinish then
		mat:onFinish(obj)
	end
end