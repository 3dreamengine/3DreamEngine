local lib = _3DreamEngine

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

--general material properties
function class:setColor(r, g, b, a)
	self.color = {r or 1.0, g or 1.0, b or 1.0, a or 1.0}
end
function class:setAlbedoTex(tex)
	self.tex_albedo = tex
	
	if not self.mat or not self.mat.color then
		self.color = {1.0, 1.0, 1.0, 1.0}
	end
end
function class:setEmission(r, g, b)
	self.emission = {r or 0.0, g or r or 0.0, b or r or 0.0}
end
function class:setEmissionTex(tex)
	self.tex_emission = tex
	if not self.mat or not self.mat.emission then
		self.emission = {1.0, 1.0, 1.0}
	end
end
function class:setAOTex(tex)
	self.tex_ao = tex
end
function class:setNormalTex(tex)
	self.tex_normal = tex
end

--roughness-metallic workflow
function class:setRoughness(r)
	self.roughness = r
end
function class:setMetallic(m)
	self.metallic = m
end
function class:setRoughnessTex(tex)
	self.tex_roughness = tex
	
	if not self.mat or not self.mat.roughness then
		self.roughness = 1.0
	end
end
function class:setMetallicTex(tex)
	self.tex_metallic = tex
	
	if not self.mat or not self.mat.metallic then
		self.metallic = 1.0
	end
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