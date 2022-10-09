local lib = _3DreamEngine

--creates an empty material
function lib:newMaterial(name)
	return setmetatable({
		color = { 0.5, 0.5, 0.5, 1.0 },
		emission = { 0.0, 0.0, 0.0 },
		roughness = 1,
		metallic = 1,
		alpha = false,
		discard = false,
		alphaCutoff = 0.5, --todo
		name = name or "None",
		ior = 1.0,
		translucent = 0.0,
		library = false,
		cullMode = "back",
	}, self.meta.material)
end

local class = {
	link = { "clone", "shader", "material" },
	
	setterGetter = {
		alpha = "boolean",
		discard = "boolean",
		dither = "boolean",
		translucent = "number",
		cullMode = "string",
		shadow = true,
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

function class:preload(force)
	if self.preloaded then
		return
	else
		self.preloaded = true
	end
	
	--preload textures
	for d, s in pairs(self) do
		if type(s) == "string" and love.filesystem.getInfo(s, "file") then
			lib:getImage(s, force)
		end
	end
	
	--preload shader
	--todo
end

return class