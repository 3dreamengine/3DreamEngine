---@type Dream
local lib = _3DreamEngine

---Creates a new sprite batch
---@param texture Texture @ optional
---@param emissionTexture Texture @ optional
---@param normalTexture Texture @ optional
function lib:newSpriteBatch(texture, emissionTexture, normalTexture)
	---@type DreamSpriteBatch
	local sb = setmetatable(lib.classes.sprite.getQuadMesh(1, 1, 0, 0, 1, 1), self.meta.spriteBatch)
	
	sb.material:setAlbedoTexture(texture)
	sb.material:setEmissionTexture(emissionTexture)
	sb.material:setNormalTexture(normalTexture)
	sb.material:setAlpha()
	sb.material:setCullMode("none")
	sb.material:setParticle(true)
	
	sb.sort = true
	sb.vertical = 0.0
	
	sb.instances = { }
	
	sb:resize(16)
	
	return sb
end

---A spritebatch allows for easy, performant, z sorted and camera facing sprites
---@class DreamSpriteBatch : DreamInstancedMesh
local class = {
	links = { "mesh", "spriteBatch" },
}

---Round the mesh size to the next multiple of that number to avoid unreasonable small resizes
local minIncreaseStep = 16

--instance mesh
local instanceFormat = {
	{ "InstanceCenter", "float", 3 }, -- x, y, z
	{ "InstanceRotation", "float", 1 }, -- rotation
	{ "InstanceSize", "float", 2 }, -- size
	{ "InstanceTexOffset", "float", 2 }, -- uv offset
	{ "InstanceTexScale", "float", 2 }, -- uv scale
	{ "InstanceEmission", "float", 1 }, -- emission
	{ "InstanceColor", "byte", 4 }, -- color
}

--sorter (surprisingly this works faster than caching the distances
local sortingCamPos
local sortFunction = function(a, b)
	local distA = (a[1] - sortingCamPos[1]) ^ 2 + (a[2] - sortingCamPos[2]) ^ 2 + (a[3] - sortingCamPos[3]) ^ 2
	local distB = (b[1] - sortingCamPos[1]) ^ 2 + (b[2] - sortingCamPos[2]) ^ 2 + (b[3] - sortingCamPos[3]) ^ 2
	return distA > distB
end

---Clear the batch
function class:clear()
	self.instances = { }
end

---Add a new sprite to this batch, uses current color state
---@param x number
---@param y number
---@param z number
---@param rot number @ rotation at the Z axis, 0 by default
---@param sx number @ horizontal scale, default 1
---@param sy number @ vertical scale, or sx
---@param emission number @ optional emission factor, requires set emission texture
function class:add(x, y, z, rot, sx, sy, emission)
	self:set(#self.instances + 1, x, y, z, rot, sx, sy, emission)
end

---Add a new sprite with given quad to this batch, uses current color state
---@param quad Quad
---@param x number
---@param y number
---@param z number
---@param rot number @ rotation at the Z axis, 0 by default
---@param sx number @ horizontal scale, default 1
---@param sy number @ vertical scale, or sx
---@param emission number @ optional emission factor, requires set emission texture
function class:addQuad(quad, x, y, z, rot, sx, sy, emission)
	self:setQuad(#self.instances + 1, quad, x, y, z, rot, sx, sy, emission)
end

---Sets an existing sprite
---@see DreamSpriteBatch#add
function class:set(index, x, y, z, rot, sx, sy, emission)
	assert(index <= #self.instances + 1, "Index out of bounds!")
	local r, g, b, a = love.graphics.getColor()
	self.instances[index] = { x, y, z, rot or 0, sx or 1, sy or sx or 1, 0, 0, 1, 1, emission or 1, r, g, b, a }
end

---Sets an existing sprite
---@see DreamSpriteBatch#add
function class:setQuad(index, quad, x, y, z, rot, sx, sy, emission)
	assert(index <= #self.instances + 1, "Index out of bounds!")
	local qx, qy, w, h = quad:getViewport()
	local sw, sh = quad:getTextureDimensions()
	local ratio = h / w
	local r, g, b, a = love.graphics.getColor()
	self.instances[index] = { x, y, z, rot or 0, sx or 1, (sy or sx or 1) * ratio, qx / sw, qy / sh, w / sw, h / sh, emission or 1, r, g, b, a }
end

---Resizes the spritebatch, usually called automatically
---@param size number
function class:resize(size)
	self.spriteInstanceMesh = love.graphics.newMesh(instanceFormat, size, "triangles", "dynamic")
	
	--attach instance mesh
	local mesh = lib.classes.mesh.getMesh(self, "mesh")
	for _, s in pairs({ "InstanceCenter", "InstanceRotation", "InstanceSize", "InstanceTexScale", "InstanceTexOffset", "InstanceEmission", "InstanceColor" }) do
		mesh:detachAttribute(s)
		mesh:attachAttribute(s, self.spriteInstanceMesh, "perinstance")
	end
end

---@private
function class:getMesh(name)
	name = name or "mesh"
	
	local mesh = lib.classes.mesh.getMesh(self, name)
	
	if name == "mesh" then
		if #self.instances == 0 then
			return
		end
		
		--sort the sprites
		if self.sort then
			sortingCamPos = lib.camera:getPosition()
			table.sort(self.instances, sortFunction)
		end
		
		--increase mesh data if required
		if not self.spriteInstanceMesh or self.spriteInstanceMesh:getVertexCount() < #self.instances then
			self:resize(math.ceil(#self.instances / minIncreaseStep) * minIncreaseStep)
		end
		
		--fill instance buffer
		--todo cache existing vertices?
		self.spriteInstanceMesh:setVertices(self.instances)
		
		return mesh, #self.instances
	end
	
	return mesh
end

---A helper function to set whether alpha mode (true) or cutout (false) should be used. The later one will disable sorting as it is not required.
---@param enabled boolean
function class:setAlpha(enabled)
	if enabled then
		self.material:setAlpha()
		self.sort = true
	else
		self.material:setCutout()
		self.sort = false
	end
end

---Sorting only makes sense when alpha mode is enabled, and the texture is not single colored
---@param sorting boolean
function class:setSorting(sorting)
	self.sort = sorting
end

---@return boolean
function class:getSorting()
	return self.sort
end

---A verticalness of 1 draws the sprites aligned to the Y coordinate, a value of 0 fully faces the camera
---@param vertical number
function class:setVertical(vertical)
	assert(type(vertical) == "number", "expected number, got " .. type(vertical))
	self.vertical = vertical
end

---Gets the verticalness
---@return number
function class:getVertical()
	return self.vertical
end

return class