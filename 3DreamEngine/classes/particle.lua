local lib = _3DreamEngine

--todo particles do not significantly differ from objects, are they not added as tasks this a task?

--Returns a particle instance used to draw a particle
---@return DreamParticle
function lib:newParticle(texture, emissionTexture, distortionTexture)
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

---@class DreamParticle
local class = {
	links = { "particle" },
}

function class:setTexture(texture)
	self.texture = texture
end
function class:getTexture()
	return self.texture
end

function class:setEmissionTexture(texture)
	self.emission = texture and 1 or 0
	self.emissionTexture = texture
end
function class:getEmissionTexture()
	return self.emissionTexture
end

function class:setDistortionTexture(distortionTexture)
	self.distortionTexture = distortionTexture
end
function class:getDistortionTexture()
	return self.distortionTexture
end

---Emission strength
---@param emission number
function class:setEmission(emission)
	self.emission = emission
end
function class:getEmission()
	return self.emission
end

---Distortion strength
---@param distortion number
function class:getDistortion(distortion)
	self.distortion = distortion
end
function class:getDistortion()
	return self.distortion
end

---Blend between billboard and vertical billboard
---@param vertical boolean
function class:setVertical(vertical)
	self.vertical = vertical
end
function class:getVertical()
	return self.vertical
end

---Use alpha pass
---@param alpha boolean
function class:setAlpha(alpha)
	self.alpha = alpha
end
function class:getAlpha()
	return self.alpha
end

function class:clone()
	return setmetatable({
		texture = self.texture,
		emissionTexture = self.emissionTexture,
		distortionTexture = self.distortionTexture,
		emission = self.emission,
		distortion = self.distortion,
		vertical = self.vertical,
		alpha = self.alpha,
	}, lib.meta.particle)
end

function class:getID()
	return (self.emissionTexture and 2 or 1) + (self.distortionTexture and 2 or 0)
end

return class