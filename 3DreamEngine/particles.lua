--[[
#part of the 3DreamEngine by Luke100000
particles.lua - particle spritebatches
--]]

local lib = _3DreamEngine

if not love.graphics then
	return
end

local minIncreaseStep = 16
local maxCount = 1024 * 32

--instancemesh
local instanceFormat = {
	{ "InstanceCenter", "float", 3 }, -- x, y, z
	{ "InstanceRotation", "float", 1 }, -- rotation
	{ "InstanceSize", "float", 2 }, -- size
	{ "InstanceTexOffset", "float", 2 }, -- uv offset
	{ "InstanceTexScale", "float", 2 }, -- uv scale
	{ "InstanceEmission", "float", 1 }, -- emission
	{ "InstanceDistortion", "float", 1 }, -- distortion strength
	{ "InstanceColor", "byte", 4 }, -- color
}

--quad
local f = {
	{ "VertexPosition", "float", 3 }, -- x, y, z
	{ "VertexTexCoord", "float", 2 }, -- uv
}
local mesh = love.graphics.newMesh(f, {
	{ -0.5, -0.5, 0.0, 1.0, 1.0 },
	{ 0.5, -0.5, 0.0, 0.0, 1.0 },
	{ 0.5, 0.5, 0.0, 0.0, 0.0 },
	{ -0.5, 0.5, 0.0, 1.0, 0.0 },
}, "fan", "static")


--sorter (surprisingly this works faster than caching the distances
local sortingCamPos
local sortFunction = function(a, b)
	local distA = (a[1] - sortingCamPos[1]) ^ 2 + (a[2] - sortingCamPos[2]) ^ 2 + (a[3] - sortingCamPos[3]) ^ 2
	local distB = (b[1] - sortingCamPos[1]) ^ 2 + (b[2] - sortingCamPos[2]) ^ 2 + (b[3] - sortingCamPos[3]) ^ 2
	return distA > distB
end

local meta = {
	--clear the batch
	clear = function(self)
		self.instances = { }
	end,
	
	--add a new particle to this batch
	add = function(self, x, y, z, rot, sx, sy, emission, distortion)
		local n = #self.instances
		if n < maxCount then
			local r, g, b, a = love.graphics.getColor()
			self.instances[n + 1] = { x, y, z, rot or 0, sx, sy or sx or 1, 0, 0, 1, 1, emission or (self.emissionTexture and 1 or 0), distortion or 1, r, g, b, a }
		end
	end,
	
	--add a new particle with quad to this batch
	addQuad = function(self, quad, x, y, z, rot, sx, sy, emission, distortion)
		local n = #self.instances
		if n < maxCount then
			local qx, qy, w, h = quad:getViewport()
			local sw, sh = quad:getTextureDimensions()
			local ratio = h / w
			local r, g, b, a = love.graphics.getColor()
			self.instances[n + 1] = { x, y, z, rot or 0, sx or 1, (sy or sx or 1) * ratio, qx / sw, qy / sh, w / sw, h / sh, emission or (self.emissionTexture and 1 or 0), distortion or 1, r, g, b, a }
		end
	end,
	
	--present the batch
	present = function(self, camPos)
		if #self.instances == 0 then
			return
		end
		
		if self.sort and self.alpha then
			sortingCamPos = camPos
			table.sort(self.instances, sortFunction)
		end
		
		--increase mesh data if required
		if not instanceMesh or instanceMesh:getVertexCount() < #self.instances then
			_G.instanceMesh = love.graphics.newMesh(instanceFormat, math.ceil(#self.instances / minIncreaseStep) * minIncreaseStep, "triangles", "dynamic")
			
			--attach instance mesh
			for d, s in pairs({ "InstanceCenter", "InstanceRotation", "InstanceSize", "InstanceTexScale", "InstanceTexOffset", "InstanceEmission", "InstanceDistortion", "InstanceColor" }) do
				mesh:detachAttribute(s)
				mesh:attachAttribute(s, instanceMesh, "perinstance")
			end
		end
		
		--fill instance buffer
		instanceMesh:setVertices(self.instances)
		
		mesh:setTexture(self.texture)
		
		--draw
		love.graphics.drawInstanced(mesh, #self.instances)
	end,
	
	--sets texture for diffuse lighting
	setTexture = function(self, tex)
		assert(tex, "Expected texture, got nil")
		self.texture = tex
	end,
	getTexture = function(self)
		return self.texture
	end,
	
	--sets texture for emission
	setEmissionTexture = function(self, tex)
		assert(tex, "Expected texture, got nil")
		self.emissionTexture = tex
	end,
	getEmissionTexture = function(self)
		return self.emissionTexture
	end,
	
	--sets texture for emission
	setDistortionTexture = function(self, tex)
		assert(tex, "Expected texture, got nil")
		self.distortionTexture = tex
	end,
	getDistortionTexture = function(self)
		return self.distortionTexture
	end,
	
	--toggle sorting
	setSorting = function(self, enabled)
		self.sort = enabled or false
	end,
	getSorting = function(self)
		return self.sort
	end,
	
	--toggle sorting
	setAlpha = function(self, enabled)
		self.alpha = enabled or false
	end,
	getAlpha = function(self)
		return self.alpha
	end,
	
	--set vertical alignment
	setVertical = function(self, vertical)
		assert(type(vertical) == "number", "expected number, got " .. type(vertical))
		self.vertical = vertical
	end,
	getVertical = function(self)
		return self.vertical
	end,
	
	--returns current amount of instances
	getCount = function(self)
		return #self.instance
	end,
}

function lib:newParticleBatch(texture, emissionTexture, distortionTexture)
	local p = { }
	
	p.texture = texture
	p.emissionTexture = emissionTexture
	p.distortionTexture = distortionTexture
	
	p.alpha = true
	p.sort = true
	p.vertical = 0.0
	
	p.instances = { }
	
	return setmetatable(p, { __index = meta })
end