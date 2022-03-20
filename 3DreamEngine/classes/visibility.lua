local lib = _3DreamEngine

local class = { }

function class:setLOD(min, max)
	self.LOD_min = min
	self.LOD_max = max
end
function class:getLOD()
	return self.LOD_min, self.LOD_max
end

function class:setVisible(b)
	self:setRenderVisibility(b)
	self:setShadowVisibility(b)
end

function class:setRenderVisibility(b)
	if self.class == "object" then
		for d,s in pairs(self.objects) do
			s:setRenderVisibility(b)
		end
		for d,s in pairs(self.meshes) do
			s:setRenderVisibility(b)
		end
	else
		self.renderVisibility = b or false
	end
end
function class:getRenderVisibility()
	return self.renderVisibility
end

function class:setShadowVisibility(b)
	if self.class == "object" then
		for d,s in pairs(self.objects) do
			s:setShadowVisibility(b)
		end
		for d,s in pairs(self.meshes) do
			s:setShadowVisibility(b)
		end
	else
		self.shadowVisibility = b or false
	end
end
function class:getShadowVisibility()
	return self.shadowVisibility 
end

function class:setFarVisibility(b)
	if self.class == "object" then
		for d,s in pairs(self.objects) do
			s:setFarVisibility(b)
		end
		for d,s in pairs(self.meshes) do
			s:setFarVisibility(b)
		end
	else
		self.farVisibility = b
	end
end
function class:getFarVisibility()
	return self.farVisibility == true
end

return class