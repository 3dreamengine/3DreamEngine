local p = { }

local lib = _3DreamEngine

require(lib.root .. "/physicsFunctions")

--wraper for the physics object
local colliderMeta = {
	getPosition = function(self)
		local x, y = self.body:getWorldCenter()
		return x, self.y, y
	end,
	
	getVelocity = function(self)
		return self.body:getLinearVelocity()
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
				table.insert(g, self:add(s, bodyType, x, y, z))
			end
			return g
		else
			local c = { }
			
			c.typ = shape.typ
			c.normals = shape.normals
			c.highest = shape.highest
			c.lowest = shape.lowest
			
			c.height = shape.height or 1.0
			
			c.ay = 0
			
			c.y = y or 0
			
			c.stuck = 0
			
			c.body = love.physics.newBody(self.world, x or 0, z or 0, bodyType or "static")
			c.body:setUserData(c)
			c.body:setLinearDamping(10)
			
			for index,shape in ipairs(shape.objects) do
				love.physics.newFixture(c.body, shape):setUserData(index)
			end
			
			return setmetatable(c, {__index = colliderMeta})
		end
	end,
	
	update = function(self, dt)
		for d,s in ipairs(self.world:getBodies()) do
			local c = s:getUserData()
			if c.typ == "circle" then
				--store old pos for emergency reset
				if c.stuck <= 0 then
					c.oldX, c.oldZ = c.body:getPosition()
					c.oldY = c.y
				end
				
				--gravity
				c.ay = c.ay - dt * 10
				
				--update vertical position
				c.y = c.y + c.ay * dt
				
				--clear collision data
				c.newY = false
				c.topY = false
				c.bottomY = false
				c.groundNormal = vec3(0, 0, 0)
			end
		end
		
		self.world:update(dt)
		
		for d,s in ipairs(self.world:getBodies()) do
			local c = s:getUserData()
			if c.typ == "circle" then
				--stuck between roof and floor, reset position
				local h = c.newY or c.y
				if c.bottomY and h < c.bottomY or c.topY and h + c.height > c.topY then
--					c.y = c.oldY
--					c.ay = 0
--					c.body:setPosition(c.oldX, c.oldZ)
--					c.body:getLinearVelocity(0, 0)
--					c.body:setAngularVelocity(0)
--					c.body:setAwake(true)
--					c.newY = false
--					c.groundNormal = vec3(0, 0, 0)
				end
				
				--perform step
				if c.newY then
					c.ay = 0
					c.y = c.newY
				end
				
				--anti stuck engine
				if c.topY and c.bottomY and c.topY - c.bottomY < c.height + 0.1 then
					c.stuck = 5
				else
					c.stuck = c.stuck - 1
				end
				
				--jump
				if c.groundNormal.y > 0 then
					if love.keyboard.isDown("space") then
						c.ay = 5
					end
					if love.keyboard.isDown(",") then
						c.ay = 10
					end
				end
			end
		end
	end
}

local objectMeta = { }

--tries to resolve a collision and returns true if failed to do so
local function attemptSolve(a, b)
	local colliderA = a:getBody():getUserData()
	local colliderB = b:getBody():getUserData()
	
	--triangulate
	local x, y = b:getBody():getLocalPoint(a:getBody():getWorldPoint(0, 0))
	local x1, y1, x2, y2, x3, y3 = b:getShape():getPoints()
	local w1, w2, w3 = lib:getBarycentric(x, y, x1, y1, x2, y2, x3, y3)
	
	local index = b:getUserData()
	
	local highest = colliderB.highest[index]
	local h = colliderB.y + math.min(highest[1] * w1 + highest[2] * w2 + highest[3] * w3, math.max(highest[1], highest[2], highest[3]))
	
	local lowest = colliderB.lowest[index]
	local l = colliderB.y + math.max(lowest[1] * w1 + lowest[2] * w2 + lowest[3] * w3, math.min(lowest[1], lowest[2], lowest[3]))
	
	--collision
	local coll = colliderA.y < h and colliderA.y + colliderA.height > l
	
	--ground touches
	if coll then
		local n = colliderB.normals[index]
		local normal = n[1] * w1 + n[2] * w2 + n[3] * w3
		colliderA.groundNormal = colliderA.groundNormal + normal:normalize()
	end
	
	--mark top and bottom
	local stepSize = 0.35
	if h + l > colliderA.y*2 + colliderA.height then
		--top
		colliderA.topY = math.min(colliderA.topY or l, l)
		
		--step
		if coll then
			local diff = colliderA.y + colliderA.height - l
			if diff > 0 and diff < stepSize then
				colliderA.newY = math.min(colliderA.newY or (l - colliderA.height), l - colliderA.height)
				return false
			end
		end
	else
		--bottom
		colliderA.bottomY = math.min(colliderA.bottomY or h, h)
		
		--step
		if coll then
			local diff = h - colliderA.y
			if diff > 0 and diff < (love.keyboard.isDown("r") and 1000 or stepSize) then
				colliderA.newY = math.max(colliderA.newY or h, h)
				return false
			end
		end
	end
	
	return coll
end

print("unstuck only -> if the vertical spacing gets bigger valid, else reset")

--preSolve event to decide wether a collision happens
local function preSolve(a, b, c)
	local t1 = a:getBody():getType() == "dynamic"
	local t2 = b:getBody():getType() == "dynamic"
	
	local coll = true
	if t1 and not t2 then
		coll = attemptSolve(a, b)
	elseif t2 and not t1 then
		coll = attemptSolve(b, a)
	end
	
	c:setEnabled(coll)
end

--creates a new world
function p.newWorld()
	local w = { }
	
	w.world = love.physics.newWorld(0, 0, false)
	
	w.world:setCallbacks(nil, nil, preSolve, nil)
	
	return setmetatable(w, {__index = worldMeta})
end

--creates a new mesh object used to control a set of triangle collider
function p:newMesh(obj)
	local n = { }
	
	if obj.physics then
		n.typ = "group"
		n.objects = { }
		for d,phy in pairs(obj.physics) do
			table.insert(n.objects, lib:getPhysicsObject(phy))
		end
	elseif obj.objects then
		obj.physics = { }
		for d,s in pairs(obj.objects) do
			obj.physics[d] = lib:getPhysicsData(s)
		end
		return self:newMesh(obj)
	end
	
	assert(#n.objects > 0, "Object has been cleaned up or is invalid, 'faces' and 'vertices' buffers are required!")
	
	return setmetatable(n, {__index = objectMeta})
end

--creates a new circle collider
function p:newCircle(radius, height)
	local n = { }
	
	n.typ = "circle"
	n.objects = {
		love.physics.newCircleShape(radius)
	}
	n.height = height
	
	return setmetatable(n, {__index = objectMeta})
end

return p