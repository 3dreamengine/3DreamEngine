local lib = _3DreamEngine

return {
	link = {"clone", "shader", "material"},
	
	setterGetter = {
		alpha = "boolean",
		discard = "boolean",
		dither = "boolean",
		translucent = "number",
		cullMode = "string",
		
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
	
	--translucent
	setTranslucent = function(self, translucent)
		self.translucent = translucent or 0.0
		if self.translucent > 0.0 then
			self:setMeshCullMode("none")
		end
	end,
	
	--general settings
	setIOR = function(self, ior)
		self.ior = ior or 1.0
	end,
	
	--general material properties
	setColor = function(self, r, g, b, a)
		self.color = {r or 1.0, g or 1.0, b or 1.0, a or 1.0}
	end,
	setAlbedoTex = function(self, tex)
		self.tex_albedo = tex
		
		if not self.mat or not self.mat.color then
			self.color = {1.0, 1.0, 1.0, 1.0}
		end
	end,
	setEmission = function(self, r, g, b)
		self.emission = {r or 0.0, g or r or 0.0, b or r or 0.0}
	end,
	setEmissionTex = function(self, tex)
		self.tex_emission = tex
		if not self.mat or not self.mat.emission then
			self.emission = {1.0, 1.0, 1.0}
		end
	end,
	setAOTex = function(self, tex)
		self.tex_ao = tex
	end,
	setNormalTex = function(self, tex)
		self.tex_normal = tex
	end,
	
	--roughness-metallic workflow
	setRoughness = function(self, r)
		self.roughness = r
	end,
	setMetallic = function(self, m)
		self.metallic = m
	end,
	setRoughnessTex = function(self, tex)
		self.tex_roughness = tex
		
		if not self.mat or not self.mat.roughness then
			self.roughness = 1.0
		end
	end,
	setMetallicTex = function(self, tex)
		self.tex_metallic = tex
		
		if not self.mat or not self.mat.metallic then
			self.metallic = 1.0
		end
	end,
	
	preload = function(self, force)
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
		
		--preload modules
		if self.modules then
			for d,_ in pairs(self.modules) do
				local m = lib:getShaderModule(d)
				if m.preload then
					m:preload(self, force)
				end
			end
		end
	end,
}