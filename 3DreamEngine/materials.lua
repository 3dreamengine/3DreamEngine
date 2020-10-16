--[[
#part of the 3DreamEngine by Luke100000
materials.lua - load and process materials
--]]

local lib = _3DreamEngine

--creates an empty material
function lib:newMaterial(name, dir)
	return {
		color = {0.5, 0.5, 0.5, 1.0},
		glossiness = 0.1,
		specular = 0.5,
		emission = {0.0, 0.0, 0.0},
		roughness = 0.5,
		metallic = 0.0,
		solid = true,
		alpha = false,
		name = name or "None",        --name, used for texture linking
		dir = dir,                    --directory, used for texture linking
		ior = 1.0,
		translucent = 0.0,
	}
end

--recognise mat files and directories with an albedo texture or "material.mat" as materials
--if the material is a directory it will skip the structured texture linking and uses the string.find to support extern material libraries
function lib:loadMaterialLibrary(path, prefix)
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
				v.name = prefix .. i
				self:finishMaterial(v)
				self.materialLibrary[v.name] = v
			end
		elseif love.filesystem.getInfo(p .. "/material.mat") then
			--directory is a material since it contains an anonymous material file (not nested, directly returns material without name)
			local dummyObj = {materials = { }, dir = p}
			self.loader["mat"](self, dummyObj, p .. "/material.mat", true)
			
			local mat = dummyObj.materials.material
			mat.dir = p
			mat.name = prefix .. s
			self:finishMaterial(mat)
			self.materialLibrary[mat.name] = mat
		elseif self.imageDirectories[p] then
			--directory is a material since it contains at least one texture
			local mat = self:newMaterial(prefix .. s, p)
			self:finishMaterial(mat)
			self.materialLibrary[mat.name] = mat
		elseif love.filesystem.getInfo(p, "directory") then
			--directory is not a material, but maybe its child directories
			self:loadMaterialLibrary(p, prefix .. s .. "/")
		end
	end
end

--link textures to material
local function texSetter(mat, typ, tex)
	--use the setter function to overwrite color
	local func = "set" .. typ:sub(1, 1):upper() .. typ:sub(2) .. "Tex"
	if mat[func] then
		mat[func](mat, tex)
	else
		mat["tex_" .. typ] = tex
	end
end

function lib:finishMaterial(mat, obj)
	setmetatable(mat, self.meta.material)
	
	for _,typ in ipairs({"albedo", "normal", "roughness", "metallic", "emission", "ao", "specular", "glossiness"}) do
		local custom = mat["tex_" .. typ]
		mat["tex_" .. typ] = nil
		if custom then
			if type(custom) == "userdata" then
				texSetter(mat, typ, custom)
			else
				--path specified
				custom = custom and custom:match("(.+)%..+") or custom
				for _,p in pairs({
					custom,
					(mat.dir and (mat.dir .. "/") or "") .. custom,
				}) do
					if self.images[p] then
						texSetter(mat, typ, self.images[p])
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
						texSetter(mat, typ, v)
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
					texSetter(mat, typ, self.images[p])
					break
				end
			end
		end
	end
	
	--combiner
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
	
	--last callback
	if mat.onFinish then
		mat:onFinish(obj)
	end
	
	--release original mat file
	mat.mat = nil
end