---@type PhysicsExtension
local physicsExtension = _G._PhysicsExtension

function physicsExtension:newCylinder(radius, height, bottom)
	local n = { }
	
	n.typ = "cylinder"
	n.loveShapes = {
		love.physics.newCircleShape(radius)
	}
	
	n.radius = radius
	n.top = height - (bottom or 0)
	n.bottom = bottom or 0
	
	return setmetatable(n, { __index = objectMeta })
end