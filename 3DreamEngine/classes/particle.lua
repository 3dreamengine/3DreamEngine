local lib = _3DreamEngine

--returns a particle instance used to draw a particle
function lib:newParticle(texture, emissionTexture, distortionTexture)
	local color = {love.graphics.getColor()}
	
	assert(texture, "texture required")
	
	local p = {
		texture = texture,
		emissionTexture = emissionTexture or false,
		distortionTexture = distortionTexture or false,
		emission = distortionTexture and 1.0 or 0.0,
		distortion = 1.0,
		vertical = 0.0,
		alpha = true,
	}
	
	return setmetatable(p, self.meta.particle)
end

return {
	link = {"particle"},
	
	setterGetter = {
		texture = "userdata",
		emissionTexture = "userdata",
		distortionTexture = "userdata",
		emission = "number",
		distortion = "number",
		vertical = "number",
		alpha = "boolean",
	},
	
	setEmissionTexture = function(self, tex)
		self.emission = tex and 1 or 0
		emissionTexture = tex
	end,
	
	clone = function(self)
		return setmetatable({
			texture = self.texture,
			emissionTexture = self.emissionTexture,
			distortionTexture = self.distortionTexture,
			emission = self.emission,
			distortion = self.distortion,
			vertical = self.vertical,
			alpha = self.alpha,
		}, lib.meta.particle)
	end,
	
	getID = function(self)
		return (self.emissionTexture and 2 or 1) + (self.distortionTexture and 2 or 0)
	end
}