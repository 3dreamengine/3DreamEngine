---@type PhysicsExtension
local physicsExtension = _G._PhysicsExtension

---@class DreamCollider
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
	return vec3(cx, self.vy, cy)
end

function methods:applyForce(fx, fy, fz)
	self.fx = self.fx + fx
	self.fy = self.fy + fy
	self.fz = self.fz + fz
end

function methods:applyLinearImpulse(fx, fy, fz)
	self.vy = self.vy + fy
	self.body:applyLinearImpulse(fx, fz)
end

function methods:applyTorque(torque)
	self.torque = self.torque + torque
end

function methods:setStepHeight(h)
	self.stepHeight = h
end

function methods:getStepHeight(h)
	return self.stepHeight
end

function methods:setFriction(f)
	self.staticFriction = f
	self.slidingFriction = f
	for _, fixture in ipairs(self.fixtures) do
		fixture:setFriction(f)
	end
end

function methods:setDensity(density)
	for _, fixture in ipairs(self.fixtures) do
		fixture:setDensity(density)
	end
	self.body:resetMassData()
end

function methods:destroy()
	self.body:destroy()
end

local colliderMeta = { __index = methods }

function physicsExtension:newCollisionMesh(world, shape, bodyType, x, y, z)
	---@type DreamCollider
	local c = setmetatable({ }, colliderMeta)
	
	c.shape = shape
	c.world = world
	c.stepHeight = 0.25
	
	--force applied
	c.fx = 0
	c.fy = 0
	c.fz = 0
	c.torque = 0
	
	c.vy = 0
	c.y = y or 0
	
	c.staticFriction = 0
	c.slidingFriction = 0
	
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
	c.body:setActive(true)
	
	c.fixtures = { }
	
	--add the shapes
	for index, loveShape in ipairs(shape.loveShapes) do
		local fixture = love.physics.newFixture(c.body, loveShape)
		fixture:setUserData(index)
		table.insert(c.fixtures, fixture)
	end
	
	c:setFriction(0.25)
	c:setDensity(100)
	
	return c
end