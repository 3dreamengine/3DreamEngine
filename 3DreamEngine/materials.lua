--[[
#part of the 3DreamEngine by Luke100000
materials.lua - load and process materials
--]]

local lib = _3DreamEngine

--creates an empty material
function lib:newMaterial(name, dir)
	return setmetatable({
		color = {0.5, 0.5, 0.5, 1.0},
		emission = {0.0, 0.0, 0.0},
		roughness = 0.5,
		metallic = 0.0,
		alpha = false,
		discard = false,
		name = name or "None",        --name, used for texture linking
		dir = dir,                    --directory, used for texture linking
		ior = 1.0,
		translucent = 0.0,
		library = false,
	}, self.meta.material)
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
				v.library = true
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
			mat.library = true
			self.materialLibrary[mat.name] = mat
		elseif self:getImagePath(p .. "/albedo") then
			--directory is a material since it contains at least one texture
			local mat = self:newMaterial(prefix .. s, p)
			self:finishMaterial(mat)
			mat.library = true
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
	for _,typ in ipairs({"albedo", "normal", "roughness", "metallic", "emission", "ao", "material"}) do
		local custom = mat["tex_" .. typ]
		mat["tex_" .. typ] = nil
		if custom then
			if type(custom) == "userdata" then
				texSetter(mat, typ, custom)
			elseif type(custom) == "string" then
				--path specified
				custom = custom and custom:match("(.+)%..+") or custom
				for _,p in pairs({
					custom,
					(mat.dir and (mat.dir .. "/") or "") .. custom,
				}) do
					if self:getImagePath(p) then
						texSetter(mat, typ, self:getImagePath(p))
						break
					end
				end
			end
		elseif not obj then
			--this is a material library entry and it expects correctly named files
			local v = self:getImagePath(mat.dir .. "/" .. typ)
			if v then
				texSetter(mat, typ, v)
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
				if self:getImagePath(p) then
					texSetter(mat, typ, self:getImagePath(p))
					break
				end
			end
		end
	end
	
	--combiner
	if not mat["tex_material"] then
		if mat["tex_metallic"] or mat["tex_roughness"] or mat["tex_ao"] then
			mat["tex_material"] = self:combineTextures(mat["tex_roughness"], mat["tex_metallic"], mat["tex_ao"])
		end
	end
	
	--enable shader modules
	if mat.shaderModules then
		for _,s in ipairs(mat.shaderModules) do
			mat:activateShaderModule(s)
		end
	end
	
	--last callback
	if mat.onFinish then
		mat:onFinish(obj)
	end
	
	--release original mat file
	mat.mat = nil
end