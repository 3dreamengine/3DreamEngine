---@type PhysicsExtension
local physicsExtension = _G._PhysicsExtension

---@class Collider
local methods = { }

function methods:getPosition()
	local x, y = self.body:getWorldCenter()
	return vec3(x, self.y, y)
end

function methods:getBody()
	return self.body
end

function methods:getVelocity()
	local cx, cy = self.body:getLinearVelocity()
	return vec3(cx, self.ay, cy)
end

function methods:applyForce(fx, fy)
	return self.body:applyForce(fx, fy)
end

function methods:setStepHeight(h)
	self.stepHeight = h
end

function methods:getStepHeight(h)
	return self.stepHeight
end

local colliderMeta = { __index = methods }

function physicsExtension:newCollider(world, shape, bodyType, x, y, z)
	---@type Collider
	local c = { }
	
	c.shape = shape
	c.stepHeight = 0.25
	
	c.ay = 0
	c.y = y or 0
	
	--anti-stuck
	c.lastSafeX = x or 0
	c.lastSafeY = y or 0
	c.lastSafeZ = z or 0
	c.lastSafeAngle = 0
	c.lastSaveVx = 0
	c.lastSaveVy = 0
	c.lastSaveVz = 0
	c.lastSafeAngleVelocity = 0
	
	--physics body
	c.body = love.physics.newBody(world.world, x or 0, z or 0, bodyType or "static")
	c.body:setUserData(c)
	c.body:setLinearDamping(10)
	c.body:setActive(true)
	
	--add the shapes
	for index, loveShape in ipairs(shape.loveShapes) do
		love.physics.newFixture(c.body, loveShape):setUserData(index)
	end
	
	return setmetatable(c, colliderMeta)
end