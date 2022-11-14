local lib = _3DreamEngine

---Creates an empty material
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
		name = name or "None",
		ior = 1.0,
		translucency = 0.0,
		library = false,
		cullMode = "back",
	}, self.meta.material)
end

---@class DreamMaterial
local class = {
	links = { "clone", "shader", "material" },
}

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

---Sets the culling mode
---@param cullMode "CullMode"
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
		self:setMeshCullMode("none")
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

return class