local p = { }

local lib = _3DreamEngine

local root = (...)
require(root .. "/functions")

--physics object
local colliderMeta = {
	getPosition = function(self)
		local x, y = self.body:getWorldCenter()
		return vec3(x, self.y, y)
	end,
	
	getVelocity = function(self)
		local cx, cy = self.body:getLinearVelocity()
		return vec3(cx, self.ay, cy)
	end,
	
	applyForce = function(self, fx, fy)
		return self.body:applyForce(fx, fy)
	end,
}

--world metatable
local worldMeta = {
	add = function(self, shape, bodyType, x, y, z)
		if shape.typ == "group" then
			local g = { }
			for d,s in ipairs(shape.objects) do
				local c = self:add(s, bodyType, x, y, z)
				table.insert(g, c)
				c.name = shape.name
			end
			return g
		else
			local c = { }
			c.shape = shape
			c.ay = 0
			c.y = y or 0
			
			c.body = love.physics.newBody(self.world, x or 0, z or 0, bodyType or "static")
			c.body:setUserData(c)
			c.body:setLinearDamping(10)
			c.body:setActive(true)
			
			for index,shape in ipairs(shape.objects) do
				love.physics.newFixture(c.body, shape):setUserData(index)
			end
			
			return setmetatable(c, {__index = colliderMeta})
		end
	end,
	
	update = function(self, dt)
		for d,s in ipairs(self.world:getBodies()) do
			if s:getType() == "dynamic" then
				local c = s:getUserData()
				--store old pos for emergency reset
				c.oldX, c.oldZ = c.pre_oldX, c.pre_oldZ
				c.pre_oldX, c.pre_oldZ = c.body:getPosition()
				c.oldY = c.y
				
				--gravity
				c.ay = c.ay - dt * 10
				
				--update vertical position
				c.y = c.y + c.ay * dt
				
				--clear collision data
				c.newY = false
				c.topY = false
				c.bottomY = false
				c.groundNormal = false
				
				c.collided = false
			end
		end
		
		self.world:update(dt)
		
		for d,s in ipairs(self.world:getBodies()) do
			if s:getType() == "dynamic" then
				local c = s:getUserData()
				--stuck between roof and floor -> reset position
				if c.bottomY and c.topY and c.topY - c.bottomY < c.shape.height then
					c.y = c.oldY
					c.ay = 0
					c.body:setPosition(c.oldX or 0, c.oldZ or 0)
					c.body:setLinearVelocity(0, 0)
					c.pre_oldX, c.pre_oldZ = c.oldX, c.oldZ
					c.newY = nil
					c.groundNormal = nil
				end
				
				--perform step
				if c.newY then
					c.y = c.newY
					c.ay = 0
				end
			end
		end
	end
}

local objectMeta = { }

--gets the gradient of a triangle (normalized derivatives x and y from the baycentric transformation)
local function getDirection(w, x1, y1, x2, y2, x3, y3)
	local det = (x1 * y2 - x1 * y3 - x2 * y1 + x2 * y3 + x3 * y1 - x3 * y2)
	local x = (w[1] * y2 - w[1] * y3 - w[2] * y1 + w[2] * y3 + w[3] * y1 - w[3] * y2) / det
	local y = (-w[1] * x2 + w[1] * x3 + w[2] * x1 - w[2] * x3 - w[3] * x1 + w[3] * x2) / det
	local l = math.sqrt(x^2 + y^2)
	if l > 0 then
		return x / l, y / l
	else
		return 0, 0
	end
end

--tries to resolve a collision and returns true if failed to do so
local function attemptSolve(a, b)
	local colliderA = a:getBody():getUserData()
	local colliderB = b:getBody():getUserData()
	local index = b:getUserData()
	
	local highest = colliderB.shape.highest[index]
	local lowest = colliderB.shape.lowest[index]
	
	--get collision
	local x, y = b:getBody():getLocalPoint(a:getBody():getPosition())
	local x1, y1, x2, y2, x3, y3 = b:getShape():getPoints()
	
	--extend x,y to outer radius
	local radius = colliderA.shape.radius
	local tx, ty
	if radius then
		local dx, dy = getDirection(highest, x1, y1, x2, y2, x3, y3)
		tx = x + dx * radius * 2.0
		ty = y + dy * radius * 2.0
	else
		tx = x
		ty = y
	end
	
	--interpolate height
	local w1, w2, w3 = lib:getBarycentricClamped(tx, ty, x1, y1, x2, y2, x3, y3)
	local h = colliderB.y + highest[1] * w1 + highest[2] * w2 + highest[3] * w3
	
	--extend head
	local w1l, w2l, w3l
	if radius then
		local dx, dy = getDirection(lowest, x1, y1, x2, y2, x3, y3)
		tx = x - dx * radius * 2.0
		ty = y - dy * radius * 2.0
		
		w1l, w2l, w3l = lib:getBarycentricClamped(tx, ty, x1, y1, x2, y2, x3, y3)
	else
		w1l, w2l, w3l = w1, w2, w3
	end
	
	--interpolate depth
	local l = colliderB.y + lowest[1] * w1l + lowest[2] * w2l + lowest[3] * w3l
	
	--mark top and bottom
	local stepSize = 0.5
	if h + l > colliderA.y*2 + colliderA.shape.height then
		local diff = colliderA.y + colliderA.shape.height - l
		if diff > 0 and diff < stepSize then
			colliderA.newY = math.min(colliderA.newY or colliderA.y, l - colliderA.shape.height)
		elseif diff > 0 then
			colliderA.collided = true
			return true
		end
		
		--top
		colliderA.topY = math.min(colliderA.topY or l, l)
	else
		local diff = h - colliderA.y
		if diff > 0 and diff < stepSize and colliderA.ay <= 0 then
			colliderA.newY = math.max(colliderA.newY or colliderA.y, h)
			
			local n = colliderB.shape.normals[index]
			local normal = (n[1] * w1 + n[2] * w2 + n[3] * w3):normalize()
			colliderA.groundNormal = colliderA.groundNormal and colliderA.groundNormal + normal or normal
		elseif diff > 0 then
			colliderA.collided = true
			return true
		end
		
		--bottom
		colliderA.bottomY = math.max(colliderA.bottomY or h, h)
	end
	
	return false
end

--preSolve event to decide wether a collision happens
local function preSolve(a, b, c)
	local t1 = a:getBody():getType() == "dynamic"
	local t2 = b:getBody():getType() == "dynamic"
	
	local coll = true
	if t1 and not t2 then
		coll = attemptSolve(a, b)
	elseif t2 and not t1 then
		coll = attemptSolve(b, a)
	elseif t1 and t2 then
		local colliderA = a:getBody():getUserData()
		local colliderB = b:getBody():getUserData()
		coll = colliderA.y < colliderB.y + colliderB.shape.height and colliderA.y + colliderA.shape.height > colliderB.y
	end
	
	c:setEnabled(coll)
end

--creates a new world
function p:newWorld()
	local w = { }
	
	w.world = love.physics.newWorld(0, 0, false)
	
	w.world:setCallbacks(nil, nil, preSolve, nil)
	
	return setmetatable(w, {__index = worldMeta})
end

function p:newGroup()
	return {
		typ = "group",
		objects = { }
	}
end

--creates a new mesh object used to control a set of triangle collider
function p:newMesh(obj, transform)
	assert(obj.class == "object", "object expected")
	local n = self:newGroup()
	
	if obj.physics then
		for d,phy in pairs(obj.physics) do
			table.insert(n.objects, lib:getMeshPhysicsObject(phy, transform))
		end
	end
	
	for d,s in pairs(obj.objects) do
		local t = (s.transform or transform) and (s.transform or mat4:getIdentity()) * (transform or mat4:getIdentity())
		local g = self:newMesh(s, t)
		if #g.objects > 0 then
			table.insert(n.objects, g)
		end
	end
	
	return setmetatable(n, {__index = objectMeta})
end

--creates a new circle collider
function p:newCircle(radius, height)
	local n = { }
	
	n.typ = "circle"
	n.objects = {
		love.physics.newCircleShape(radius)
	}
	n.radius = radius
	n.height = height
	
	return setmetatable(n, {__index = objectMeta})
end

return p