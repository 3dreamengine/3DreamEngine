---@type PhysicsExtension
local physicsExtension = _G._PhysicsExtension

function physicsExtension:newCapsule(radius, height, bottom)
	---@type DreamCollider
	local n = { }
	
	n.typ = "capsule"
	n.loveShapes = {
		love.physics.newCircleShape(radius)
	}
	
	n.top = height - (bottom or 0)
	n.bottom = bottom or 0
	
	return setmetatable(n, { __index = objectMeta })
end