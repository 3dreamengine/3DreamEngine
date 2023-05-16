---@type Dream
local lib = _3DreamEngine

---Creates a new sprite, that is, a textured quad mesh
---@param texture Texture @ optional
---@param emissionTexture Texture @ optional
---@param normalTexture Texture @ optional
---@param quad Quad @ optional
---@return DreamSprite
function lib:newSprite(texture, emissionTexture, normalTexture, quad)
	local u1, v1, u2, v2, ratio
	if quad then
		local qx, qy, w, h = quad:getViewport()
		local sw, sh = quad:getTextureDimensions()
		ratio = h / w
		u1, v1, u2, v2 = qx / sw, qy / sh, (qx + w) / sw, (qy + h) / sh
	else
		u1, v1, u2, v2, ratio = 0, 0, 1, 1, 1
	end
	
	---@type DreamSprite
	local mesh = setmetatable(lib.classes.sprite.getQuadMesh(1, ratio, u1, v1, u2, v2), self.meta.sprite)
	
	mesh.material:setAlbedoTexture(texture)
	mesh.material:setEmissionTexture(emissionTexture)
	mesh.material:setNormalTexture(normalTexture)
	mesh.material:setAlpha()
	mesh.material:setCullMode("none")
	mesh.material:setParticle(true)
	
	return mesh
end

---A sprite represents a simple, textured quad
---@class DreamSprite : DreamMesh
local class = {
	links = { "mesh", "sprite" },
}

local normals, faces

---Builds a quad mesh
---@param sx number
---@param sy number
---@param u1 number
---@param v1 number
---@param u2 number
---@param v2 number
---@private
function class.getQuadMesh(sx, sy, u1, v1, u2, v2)
	if not normals then
		normals = lib:newDynamicBuffer()
		normals:append({ 0, 0, 1 })
		normals:append({ 0, 0, 1 })
		normals:append({ 0, 0, 1 })
		normals:append({ 0, 0, 1 })
		
		faces = lib:newDynamicBuffer()
		faces:append({ 1, 2, 3 })
		faces:append({ 1, 3, 4 })
	end
	
	local material = lib:newMaterial()
	local mesh = lib:newMesh(material)
	
	local vertices = mesh:getOrCreateBuffer("vertices")
	vertices:append({ -0.5 * sx, -0.5 * sy, 0.0 })
	vertices:append({ 0.5 * sx, -0.5 * sy, 0.0 })
	vertices:append({ 0.5 * sx, 0.5 * sy, 0.0 })
	vertices:append({ -0.5 * sx, 0.5 * sy, 0.0 })
	
	local texCoords = mesh:getOrCreateBuffer("texCoords")
	texCoords:append({ u1, v2 })
	texCoords:append({ u2, v2 })
	texCoords:append({ u2, v1 })
	texCoords:append({ u1, v1 })
	
	mesh.normals = normals
	mesh.faces = faces
	
	return mesh
end

---Returns a transform to place the quad camera facing at given position with given scale and rotation
---@param x number
---@param y number
---@param z number
---@param rotation number @ rotation at the Z axis, default 0
---@param sx number @ default 1
---@param sy number @ default sx
---@param camera DreamCamera @ defaults to the default camera
function class:getSpriteTransform(x, y, z, rotation, sx, sy, camera)
	local eye = (camera or lib.camera):getPosition()
	local at = lib.vec3(x, y, z)
	local direction = at - eye
	
	local up = lib.vec3(0.0, 1.0, 0.0)
	
	local zaxis = direction:normalize()
	local xaxis = zaxis:cross(up):normalize()
	local yaxis = xaxis:cross(zaxis)
	
	local c = math.cos(rotation or 0)
	local s = math.sin(rotation or 0)
	
	sx = sx or 1
	sy = sy or sx
	
	--This is a translate * lookTowards * zRotate * scale multiplication
	local sxc, syc, sxs, sys = sx * c, sy * c, sx * s, sy * s
	return lib.mat4(
			sxc * xaxis.x - sxs * yaxis.x, syc * yaxis.x + sys * xaxis.x, -zaxis.x, x,
			sxc * xaxis.y - sxs * yaxis.y, syc * yaxis.y + sys * xaxis.y, -zaxis.y, y,
			sxc * xaxis.z - sxs * yaxis.z, syc * yaxis.z + sys * xaxis.z, -zaxis.z, z,
			0, 0, 0, 1
	)
end

return class