local lib = _3DreamEngine

--creates an empty material
function lib:newMaterial(name)
	return setmetatable({
		color = {0.5, 0.5, 0.5, 1.0},
		emission = {0.0, 0.0, 0.0},
		roughness = 0.5,
		metallic = 0.0,
		alpha = false,
		discard = false,
		name = name or "None",
		ior = 1.0,
		translucent = 0.0,
		library = false,
	}, self.meta.material)
end

local class = {
	link = {"clone", "shader", "material"},
	
	setterGetter = {
		alpha = "boolean",
		discard = "boolean",
		dither = "boolean",
		translucent = "number",
		cullMode = "string",
		shadow = true,
		
		IOR = "getter",
		color = "getter",
		albedoTex = "getter",
		emission = "getter",
		emissionTex = "getter",
		roughness = "getter",
		roughnessTex = "getter",
		metallic = "getter",
		metallicTex = "getter",
		material = "getter",
		materialTex = "getter",
		aoTex = "getter",
	},
}

--translucent
function class:setTranslucent(translucent)
	self.translucent = translucent or 0.0
	if self.translucent > 0.0 then
		self:setMeshCullMode("none")
	end
end

function class:setIOR(ior)
	self.ior = ior or 1.0
end

function class:throwsShadow(shadow)
	assert(type(shadow) == "boolean", "boolean expected")
	self.shadow = shadow
end

function class:setColor(r, g, b, a)
	self.color = {r or 1.0, g or 1.0, b or 1.0, a or 1.0}
end
function class:setAlbedoTexture(tex)
	self.albedoTexture = tex
	
	if not self.mat or not self.mat.color then
		self.color = {1.0, 1.0, 1.0, 1.0}
	end
end
function class:setEmission(r, g, b)
	self.emission = {r or 0.0, g or r or 0.0, b or r or 0.0}
end
function class:setEmissionTexture(tex)
	self.emissionTexture = tex
	if not self.mat or not self.mat.emission then
		self.emission = {1.0, 1.0, 1.0}
	end
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
	
	if not self.mat or not self.mat.roughness then
		self.roughness = 1.0
	end
end
function class:setMetallicTexture(tex)
	self.metallicTexture = tex
	
	if not self.mat or not self.mat.metallic then
		self.metallic = 1.0
	end
end

function class:setMaterialTexture(tex)
	self.materialTexture = tex
	
	if not self.mat or not self.mat.roughness then
		self.roughness = 1.0
	end
	
	if not self.mat or not self.mat.metallic then
		self.metallic = 1.0
	end
end
function class:getMaterialTexture(tex)
	self.materialTexture = tex
end

function class:preload(force)
	if self.preloaded then
		return
	else
		self.preloaded = true
	end
	
	--preload textures
	for d,s in pairs(self) do
		if type(s) == "string" and love.filesystem.getInfo(s, "file") then
			lib:getImage(s, force)
		end
	end
	
	--preload shader
	--todo
end

return class