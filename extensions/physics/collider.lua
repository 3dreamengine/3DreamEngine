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

local colliderMeta = { __index = methods }

return function(physics, world, shape, bodyType, y)
	local c = { }
	c.shape = shape
	c.ay = 0
	c.y = y or 0
	
	c.body = love.physics.newBody(world.world, x or 0, z or 0, bodyType or "static")
	c.body:setUserData(c)
	c.body:setLinearDamping(10)
	c.body:setActive(true)
	
	for index, loveShape in ipairs(shape.loveShapes) do
		love.physics.newFixture(c.body, loveShape):setUserData(index)
	end
	
	return setmetatable(c, colliderMeta)
end