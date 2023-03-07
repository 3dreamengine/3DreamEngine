---@type Dream
local lib = _3DreamEngine

---Creates an empty material
---@param name string
---@return DreamMaterial
function lib:newMaterial(name)
	return setmetatable({
		color = { 0.5, 0.5, 0.5, 1.0 },
		emission = { 0.0, 0.0, 0.0 },
		roughness = 1,
		metallic = 1,
		alpha = false,
		discard = false,
		alphaCutoff = 0.5, --todo
		name = name or "Unnamed",
		ior = 1.0,
		translucency = 0.0,
		library = false,
		cullMode = "back",
	}, self.meta.material)
end

---A material holds textures, render settings, shader information and similar and is assigned to a mesh.
---@class DreamMaterial
local class = {
	links = { "clonable", "hasShaders", "material" },
}

---@param name string
function class:setName(name)
	self.name = lib:removePostfix(name)
end
function class:getName()
	return self.name
end

--todo merge alpha, solid and discard
function class:setAlpha(alpha)
	self.alpha = alpha
end
function class:getAlpha()
	return self.alpha
end

--todo merge alpha, solid and discard
function class:setDiscard(discard)
	self.discard = discard
end
function class:getDiscard()
	return self.discard
end

--todo merge alpha, solid and discard
function class:setDither(dither)
	self.dither = dither
end
function class:getDither()
	return self.dither
end

---@alias CullMode "back"|"front"|"none

---Sets the culling mode
---@param cullMode CullMode
function class:setCullMode(cullMode)
	self.cullMode = cullMode
end
function class:getCullMode()
	return self.cullMode
end

---Sets the object translucency (light coming through to the other side of a face), will disable mesh culling of translucency is larger than 0
---@param translucency number
function class:setTranslucency(translucency)
	self.translucency = translucency or 0.0
	if self.translucency > 0.0 then
		self:setCullMode("none")
	end
end

---Sets (not physically accurate) refraction index
---@param ior number
function class:setIOR(ior)
	self.ior = ior or 1.0
end

---Similar to shadowVisibility on meshes, this allows materials to only be visible in the render pass
---@param shadow boolean
function class:throwsShadow(shadow)
	self.shadow = shadow
end

function class:setColor(r, g, b, a)
	self.color = { r or 1.0, g or 1.0, b or 1.0, a or 1.0 }
end
function class:setAlbedoTexture(tex)
	self.albedoTexture = tex
end
function class:setEmission(r, g, b)
	self.emission = { r or 0.0, g or r or 0.0, b or r or 0.0 }
end
function class:setEmissionTexture(tex)
	self.emissionTexture = tex
end
function class:setAoTexture(tex)
	self.ambientOcclusionTexture = tex
end
function class:setNormalTexture(tex)
	self.normalTexture = tex
end

function class:setRoughness(r)
	self.roughness = r
end
function class:setMetallic(m)
	self.metallic = m
end
function class:setRoughnessTexture(tex)
	self.roughnessTexture = tex
end
function class:setMetallicTexture(tex)
	self.metallicTexture = tex
end

function class:setMaterialTexture(tex)
	self.materialTexture = tex
end
function class:getMaterialTexture(tex)
	self.materialTexture = tex
end

function class:setAlphaCutoff(alphaCutoff)
	self.alphaCutoff = alphaCutoff
end
function class:getAlphaCutoff()
	return self.alphaCutoff
end

function class:setCullMode(cullMode)
	self.cullMode = cullMode
end
function class:getCullMode()
	return self.cullMode
end

---Load textures and similar
---@param force boolean @ Bypass threaded loading and immediately load things
function class:preload(force)
	if self.preloaded then
		return
	end
	
	--preload textures
	for _, s in pairs(self) do
		if type(s) == "string" and love.filesystem.getInfo(s, "file") then
			lib:getImage(s, force)
		end
	end
	
	--preload shader
	--todo
	
	self.preloaded = true
end

---Populate from a lua file returning a material
---@param file string
function class:loadFromFile(file)
	local matLoaded = love.filesystem.load(file)()
	table.merge(self, matLoaded)
	
	self.pixelShader = lib:getShader(self.pixelShader)
	self.vertexShader = lib:getShader(self.vertexShader)
	self.worldShader = lib:getShader(self.worldShader)
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

---Looks for and assigns textures in a specific directory using an optional filter
---@param directory string
---@param filter string
function class:lookForTextures(directory, filter)
	for _, typ in ipairs({ "albedo", "normal", "roughness", "metallic", "emission", "ao", "material" }) do
		local custom = self[typ .. "Texture"]
		self[typ .. "Texture"] = nil
		
		if type(custom) == "userdata" then
			--already an image
			texSetter(self, typ, custom)
		elseif type(custom) == "string" then
			--path or name specified
			local path = lib:getImagePath(custom) or
					lib:getImagePath(directory .. "/" .. custom) or
					(love.filesystem.getInfo(custom, "file")) and custom or
					(love.filesystem.getInfo(directory .. "/" .. custom, "file")) and (directory .. "/" .. custom)
			
			if path then
				texSetter(self, typ, path)
			end
		elseif lib:getImagePath(directory .. "/" .. typ) then
			--recommending file naming is used
			texSetter(self, typ, lib:getImagePath(directory .. "/" .. typ))
		else
			--let's look for possible matches
			for name, path in pairs(lib:getImagePaths()) do
				if name:sub(1, #directory) == directory then
					local fn = name:sub(#directory + 2):lower()
					if fn:find(typ) and (not filter or fn:find(filter:lower())) then
						texSetter(self, typ, path)
						break
					end
				end
			end
		end
	end
	
	--combiner
	if not self["materialTexture"] then
		if self["metallicTexture"] or self["roughnessTexture"] or self["aoTex"] then
			self:setMaterialTexture(lib:combineTextures(self["metallicTexture"], self["roughnessTexture"], self["aoTex"]))
		end
	end
	
	--convert shader id to actual shader object
	--todo has nothing to do with name
end

return class