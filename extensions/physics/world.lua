local lib = _3DreamEngine

local methods = { }

--world metatable
function methods:add(shape, bodyType, x, y, z)
	if shape.typ then
		local c = self.physics:newCollider(self, shape, bodyType, y)
		table.insert(self.colliders, c)
		return c
	else
		local g = { }
		for _, s in ipairs(shape) do
			table.insert(g, self:add(s, bodyType, x, y, z))
		end
		return g
	end
end

function methods:update(dt)
	for _, s in ipairs(self.world:getBodies()) do
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
	
	for _, s in ipairs(self.world:getBodies()) do
		if s:getType() == "dynamic" then
			local c = s:getUserData()
			--stuck between roof and floor -> reset position
			--todo why does this happen
			if c.bottomY and c.topY and c.topY - c.bottomY < c.shape.top - c.shape.bottom then
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


--gets the gradient of a triangle (normalized derivatives x and y from the barycentric transformation)
local function getDirection(w, x1, y1, x2, y2, x3, y3)
	local det = (x1 * y2 - x1 * y3 - x2 * y1 + x2 * y3 + x3 * y1 - x3 * y2)
	local x = (w[1] * y2 - w[1] * y3 - w[2] * y1 + w[2] * y3 + w[3] * y1 - w[3] * y2) / det
	local y = (-w[1] * x2 + w[1] * x3 + w[2] * x1 - w[2] * x3 - w[3] * x1 + w[3] * x2) / det
	local l = math.sqrt(x ^ 2 + y ^ 2)
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
	local bottomHeight = colliderB.y + highest[1] * w1 + highest[2] * w2 + highest[3] * w3
	
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
	
	--interpolate height of head
	local topHeight = colliderB.y + lowest[1] * w1l + lowest[2] * w2l + lowest[3] * w3l
	
	--mark top and bottom
	local stepSize = 0.5 --todo variable!
	if bottomHeight + topHeight > colliderA.y * 2 + colliderA.shape.top + colliderA.shape.bottom then
		--the center of collision is above center of collider
		local diff = (colliderA.y + colliderA.shape.top) - topHeight
		if diff > 0 and diff < stepSize then
			colliderA.newY = math.min(colliderA.newY or colliderA.y, topHeight - colliderA.shape.top)
		elseif diff > 0 then
			colliderA.collided = true
			return true
		end
		
		--top
		colliderA.topY = math.min(colliderA.topY or topHeight, topHeight)
	else
		local diff = bottomHeight - (colliderA.y + colliderA.shape.bottom)
		if diff > 0 and diff < stepSize and colliderA.ay <= 0 then
			colliderA.newY = math.max(colliderA.newY or colliderA.y, bottomHeight - colliderA.shape.bottom)
			
			local n = colliderB.shape.normals[index]
			local normal = (n[1] * w1 + n[2] * w2 + n[3] * w3):normalize()
			colliderA.groundNormal = colliderA.groundNormal and colliderA.groundNormal + normal or normal
		elseif diff > 0 then
			colliderA.collided = true
			return true
		end
		
		--bottom
		colliderA.bottomY = math.max(colliderA.bottomY or bottomHeight, bottomHeight)
	end
	
	return false
end

--preSolve event to decide weather a collision happens
local function preSolve(fixtureA, fixtureB, collision)
	local aIsDyn = fixtureA:getBody():getType() == "dynamic"
	local bIsDyn = fixtureB:getBody():getType() == "dynamic"
	
	local coll = true
	if aIsDyn and not bIsDyn then
		coll = attemptSolve(fixtureA, fixtureB)
	elseif bIsDyn and not aIsDyn then
		coll = attemptSolve(fixtureB, fixtureA)
	elseif aIsDyn and bIsDyn then
		local colliderA = fixtureA:getBody():getUserData()
		local colliderB = fixtureB:getBody():getUserData()
		--todo
		coll = colliderA.y + colliderA.shape.bottom < colliderB.y + colliderB.shape.top and colliderA.y + colliderA.shape.top > colliderB.y + colliderB.shape.bottom
	end
	
	collision:setEnabled(coll)
end

local worldMeta = { __index = methods }

--creates a new world
return function(physics)
	local w = { }
	
	w.physics = physics
	
	w.colliders = { }
	
	w.world = love.physics.newWorld(0, 0, false)
	
	w.world:setCallbacks(nil, nil, preSolve, nil)
	
	return setmetatable(w, worldMeta)
end