return {
	link = {"clone", "shader", "material"},
	
	--general settings
	useAlphaPass = function(self, alpha)
		self.alpha = alpha or false
	end,
	setIOR = function(self, ior)
		self.ior = ior or 1.0
	end,
	
	--general material properties
	setColor = function(self, r, g, b, a)
		self.color = {r or 1.0, g or 1.0, b or 1.0, a or 1.0}
	end,
	setAlbedoTex = function(self, tex)
		self.tex_albedo = tex
		self.color = {1.0, 1.0, 1.0, 1.0}
	end,
	setEmission = function(self, r, g, b)
		self.emission = {r or 0.0, g or r or 0.0, b or r or 0.0}
	end,
	setEmissionTex = function(self, tex)
		self.tex_emission = tex
		self.emission = {1.0, 1.0, 1.0}
	end,
	setAOTex = function(self, tex)
		self.tex_ao = tex
	end,
	setNormalTex = function(self, tex)
		self.tex_normal = tex
	end,
	
	--specular-glossiness workflow
	setGlossiness = function(self, g)
		self.glossiness = g or 0.1
	end,
	setSpecular = function(self, s)
		self.specular = s or 0.5
	end,
	setGlossinessTex = function(self, tex)
		self.tex_glossiness = tex
		self.glossiness = 1.0
	end,
	setSpecularTex = function(self, tex)
		self.tex_specular = tex
		self.specular = 1.0
	end,
	
	--roughness-metallic workflow
	setRoughness = function(self, r)
		self.roughness = r
	end,
	setMetallic = function(self, m)
		self.metallic = r
	end,
	setRoughnessTex = function(self, tex)
		self.tex_roughness = tex
		self.roughness = 1.0
	end,
	setMetallicTex = function(self, tex)
		self.tex_metallic = tex
		self.metallic = 1.0
	end,
}