local p = { }

local dream = _3DreamEngine

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
			c.heights = shape.heights
			c.thickness = shape.thickness
			
			c.height = 1.75
			
			c.ay = 0
			
			c.y = y or 0
			c.newY = false
			
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
				c.ay = c.ay - dt * 10
				c.y = c.y + c.ay * dt
				
				c.newY = c.y
				c.groundNormal = vec3() --TODO
			end
		end
		
		self.world:update(dt)
		
		for d,s in ipairs(self.world:getBodies()) do
			local c = s:getUserData()
			if c.typ == "circle" then
				if c.y ~= c.newY then
					c.ay = 0
					c.y = c.newY
					
					if love.keyboard.isDown("space") then
						c.ay = 5
					end
				end
			end
		end
	end
}

local objectMeta = { }

local function attemptSolve(a, b)
	local colliderA = a:getBody():getUserData()
	local colliderB = b:getBody():getUserData()
	
	--triangulate
	local x, y = b:getBody():getLocalPoint(a:getBody():getWorldPoint(0, 0))
	local x1, y1, x2, y2, x3, y3 = b:getShape():getPoints()
	
	local det = (y2 - y3) * (x1 - x3) + (x3 - x2) * (y1 - y3)
	local w1 = ((y2 - y3) * (x - x3) + (x3 - x2) * (y - y3)) / det
	local w2 = ((y3 - y1) * (x - x3) + (x1 - x3) * (y - y3)) / det
	local w3 = 1 - w1 - w2
	
	local inside = w1 > 0 and w2 > 0 and w3 > 0
	
	local index = b:getUserData()
	
	local heights = colliderB.heights[index]
	local h = colliderB.y + heights[1] * w1 + heights[2] * w2 + heights[3] * w3
	
	local thickness = colliderB.thickness[index]
	local b = colliderB.y + thickness[1] * w1 + thickness[2] * w2 + thickness[3] * w3
	
	--collision
	local coll = colliderA.y < h and colliderA.y + colliderA.height > b
	
	--step
	if coll and h - colliderA.y < 0.25 then
		colliderA.newY = math.max(colliderA.newY or h, h)
		return false
	end
	
	return coll
end

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
			table.insert(n.objects, dream:getPhysicsObject(phy))
		end
	elseif obj.objects then
		obj.physics = { }
		for d,s in pairs(obj.objects) do
			obj.physics[d] = dream:getPhysicsData(s)
		end
		return self:newMesh(obj)
	end
	
	--assert(#n.objects > 0, "Object has been cleaned up or is invalid, 'faces' and 'vertices' buffers are required!")
	
	return setmetatable(n, {__index = objectMeta})
end

--creates a new circle collider
function p:newCircle(radius, height)
	local n = { }
	
	n.typ = "circle"
	n.normals = {
		vec3(0, -1, 0)
	}
	n.objects = {
		love.physics.newCircleShape(radius)
	}
	n.heights = {
		0
	}
	
	return setmetatable(n, {__index = objectMeta})
end

return p