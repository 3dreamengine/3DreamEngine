local lib = _3DreamEngine

---@type PhysicsExtension
local physicsExtension = _G._PhysicsExtension

--the threshold used to determine when a collision becomes "crowded".
--If a player gets stuck, it will teleport back to the last non-crowded position,.
local safeZoneHeight = 0.1

local methods = { }

function methods:setGravity(gravity)
	self.gravity = gravity
end

function methods:getGravity()
	return self.gravity
end

---@return World
function methods:getWorld()
	return self.world
end

--world metatable
function methods:add(shape, bodyType, x, y, z)
	return self.physics:newCollisionMesh(self, shape, bodyType, x, y, z)
end

function methods:update(dt)
	for _, s in ipairs(self.world:getBodies()) do
		if s:getType() == "dynamic" then
			local c = s:getUserData()
			
			--apply forces
			local mass = c.body:getMass()
			local vx, vz = c.body:getLinearVelocity()
			local va = c.body:getAngularVelocity()
			local static = vx == 0 and vz == 0
			
			--apply forces
			vx = vx + c.fx / mass * dt
			vz = vz + c.fz / mass * dt
			va = va + c.torque / mass * dt
			
			--friction
			if c.touchedFloor then
				local force = mass * self:getGravity() * (static and c.staticFriction or c.slidingFriction) * dt
				local speed = math.sqrt(vx ^ 2 + vz ^ 2)
				if speed > 0 then
					local linearForce = math.min(speed, force)
					vx = vx - vx / speed * linearForce
					vz = vz - vz / speed * linearForce
				end
				va = va - (va > 0 and 1 or -1) * math.min(math.abs(va), force)
			end
			
			--apply new speed
			c.body:setLinearVelocity(vx, vz)
			c.body:setAngularVelocity(va)
			c.vy = c.vy + c.fy * dt
			
			--reset forces
			c.fx = 0
			c.fy = 0
			c.fz = 0
			c.torque = 0
			
			--store old pos for emergency reset
			c.dx = 0
			c.dy = 0
			c.colls = 0
			
			--gravity
			c.vy = c.vy - dt * self.gravity
			
			--update vertical position
			c.y = c.y + c.vy * dt
			
			--remember the available space
			c.topY = math.huge
			c.bottomY = -math.huge
			
			--reset collision flags
			c.touchedFloor = false
			c.touchedCeiling = false
		end
	end
	
	self.world:update(dt)
	
	for _, s in ipairs(self.world:getBodies()) do
		if s:getType() == "dynamic" then
			local collider = s:getUserData()
			
			--resolve acceleration
			if collider.colls > 0 then
				collider.dx = collider.dx / collider.colls
				collider.dy = collider.dy / collider.colls
				
				local loss = math.sqrt(math.min(1, math.max(0, 1 - collider.dx ^ 2 - collider.dy ^ 2)))
				
				local f = -loss * math.abs(collider.vy) * collider.body:getMass()
				collider.body:applyLinearImpulse(collider.dx * f, collider.dy * f)
				
				collider.vy = collider.vy * (1 - loss)
			end
			
			local diff = (collider.topY - collider.bottomY) - (collider.shape.top - collider.shape.bottom)
			if diff < 0 then
				--stuck, reset to last safe position
				collider.y = collider.lastSafeY
				collider.vy = collider.lastSafeVy
				collider.body:setPosition(collider.lastSafeX, collider.lastSafeZ)
				collider.body:setAngularVelocity(-collider.lastSafeVx, -collider.lastSafeVz)
				collider.body:setAngle(collider.lastSafeAngle)
				collider.body:setAngularVelocity(-collider.lastSafeAngleVelocity)
			elseif diff > safeZoneHeight then
				--remember safe position
				collider.lastSafeY = collider.y
				collider.lastSafeX, collider.lastSafeZ = collider.body:getPosition()
				collider.lastSafeVy = collider.vy
				collider.lastSafeVx, collider.lastSafeVz = collider.body:getLinearVelocity()
				collider.lastSafeAngle = collider.body:getAngle()
				collider.lastSafeAngleVelocity = collider.body:getAngularVelocity()
			end
		end
	end
end

--gets the gradient of a triangle (normalized derivatives x and y from the barycentric transformation)
local function getDirection(w, x1, y1, x2, y2, x3, y3)
	local det = (x1 * y2 - x1 * y3 - x2 * y1 + x2 * y3 + x3 * y1 - x3 * y2)
	local x = (w[1] * y2 - w[1] * y3 - w[2] * y1 + w[2] * y3 + w[3] * y1 - w[3] * y2) / det
	local y = (-w[1] * x2 + w[1] * x3 + w[2] * x1 - w[2] * x3 - w[3] * x1 + w[3] * x2) / det
	return x, y
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
	local tx, ty = x, y
	local floorDx, floorDy = getDirection(highest, x1, y1, x2, y2, x3, y3)
	if radius then
		local l = math.sqrt(floorDx ^ 2 + floorDy ^ 2)
		if l > 0.0001 then
			tx = x + floorDx * radius / l
			ty = y + floorDy * radius / l
		end
	end
	
	--interpolate height
	local w1, w2, w3 = lib:getBarycentricClamped(tx, ty, x1, y1, x2, y2, x3, y3)
	local topY = colliderB.y + highest[1] * w1 + highest[2] * w2 + highest[3] * w3
	
	--extend head
	local w1l, w2l, w3l = w1, w2, w3
	local ceilingDx, ceilingDy = getDirection(lowest, x1, y1, x2, y2, x3, y3)
	ceilingDx = -ceilingDx
	ceilingDy = -ceilingDy
	if radius then
		local l = math.sqrt(ceilingDx ^ 2 + ceilingDy ^ 2)
		if l > 0.0001 then
			tx = x + ceilingDx * radius / l
			ty = y + ceilingDy * radius / l
			w1l, w2l, w3l = lib:getBarycentricClamped(tx, ty, x1, y1, x2, y2, x3, y3)
		end
	end
	
	--interpolate height of head
	local bottomY = colliderB.y + lowest[1] * w1l + lowest[2] * w2l + lowest[3] * w3l
	
	--check if colliding
	if colliderA.y + colliderA.shape.bottom > topY then
		colliderA.bottomY = math.max(colliderA.bottomY, topY)
		return false
	end
	if colliderA.y + colliderA.shape.top < bottomY then
		colliderA.topY = math.min(colliderA.topY, bottomY)
		return false
	end
	
	--mark top and bottom
	local floorDiff = topY - (colliderA.y + colliderA.shape.bottom)
	local ceilingDiff = (colliderA.y + colliderA.shape.top) - bottomY
	
	if ceilingDiff >= 0 and ceilingDiff < floorDiff then
		--hit the ceiling
		local possibleHeight = math.min(colliderA.topY, bottomY)
		ceilingDiff = (colliderA.y + colliderA.shape.top) - possibleHeight
		if ceilingDiff < colliderA.stepHeight then
			colliderA.topY = possibleHeight
			colliderA.y = colliderA.y - ceilingDiff
			colliderA.dx = colliderA.dx + ceilingDx
			colliderA.dy = colliderA.dy + ceilingDy
			colliderA.colls = colliderA.colls + 1
			colliderA.touchedCeiling = true
			return false
		end
	elseif floorDiff >= 0 then
		--hit the floor
		local possibleHeight = math.max(colliderA.bottomY, topY)
		floorDiff = possibleHeight - (colliderA.y + colliderA.shape.bottom)
		
		if floorDiff < colliderA.stepHeight then
			colliderA.bottomY = possibleHeight
			colliderA.y = colliderA.y + floorDiff
			colliderA.dx = colliderA.dx + floorDx
			colliderA.dy = colliderA.dy + floorDy
			colliderA.colls = colliderA.colls + 1
			colliderA.touchedFloor = true
			return false
		end
	end
	
	return true
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

function physicsExtension:newWorld()
	local w = { }
	
	w.physics = self
	
	w.gravity = 9.8
	
	w.world = love.physics.newWorld(0, 0, false)
	
	love.physics.setMeter(1)
	
	w.world:setCallbacks(nil, nil, preSolve, nil)
	
	return setmetatable(w, worldMeta)
end