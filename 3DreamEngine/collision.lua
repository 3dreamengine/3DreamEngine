local c = { }

local dream = _3DreamEngine

--get the vec3 offset of a transform object (which can be a mat4 or vec3)
local function getTranslate(s)
	return s.type == "mat4" and vec3(s[4], s[8], s[12]) or s
end
local function getTransform(s)
	return s.type == "mat4" and s or mat4:getTranslate(s)
end

--group meta
c.meta_group = {
	--add object to group
	add = function(self, o)
		if not o then
			return
		end
		
		if o.parent then
			o.parent:remove(o)
		end
		
		table.insert(self.children, o)
		o.parent = self
		
		self:apply()
	end,
	
	--remove object from group
	remove = function(self, o)
		o.parent = nil
		for d,s in pairs(self.children) do
			if s == o then
				table.remove(self.children, d)
				return true
			end
		end
		return false
	end,
	
	--reconstruct boundary
	apply = function(self)
		--get center of group, only relevant for in-boundary checks
		self.center = vec3(0, 0, 0)
		for d,s in ipairs(self.children) do
			self.center = self.center + getTranslate(s.transform)
		end
		self.center = self.center / #self.children
		
		--get max boundary size
		self.boundary = 0
		for d,s in ipairs(self.children) do
			local transform = getTranslate(s.transform)
			local size = (transform - self.center):length()
			self.boundary = math.max(self.boundary, size + s.boundary)
		end
		
		--pass updates to parent
		if self.parent then
			self.parent:apply()
		end
	end,
	
	--creates a copy with shared coll data if present
	clone = function(self)
		local children = { }
		for d,s in ipairs(self.children) do
			children[#children+1] = s:clone()
		end
		
		return {
			typ = self.typ,
			transform = self.transform and self.transform:clone() or nil,
			transformInverse = self.transformInverse and self.transformInverse:clone() or nil,
			boundary = self.boundary,
			children = children;
		}
	end,
	
	--move object, recreating boundaries for parents
	moveTo = function(self, pos, y, z)
		self.transform = y and vec3(pos, y, z) or pos
		
		if self.parent then
			self.parent:apply()
		end
	end,
}

--basic meta
c.meta_basic = {
	--reconstruct boundary
	apply = function(self)
		if self.parent then
			self.parent:apply()
		end
	end,
	
	--creates a copy with shared coll data if present
	clone = function(self)
		local n = { }
		
		for i,v in pairs(self) do
			n[i] = v
		end
		
		n.transform = self.transform and self.transform:clone() or nil
		n.transformInverse = self.transformInverse and self.transformInverse:clone() or nil
		n.size = self.size and (type(self.size) == "number" and self.size or self.size:clone()) or nil
		
		return n
	end,
	
	--move object, recreating boundaries for parents
	moveTo = function(self, pos, y, z)
		self.transform = y and vec3(pos, y, z) or pos
		
		if self.parent then
			self.parent:apply()
		end
	end
}

--group node
function c:newGroup(transform)
	local n = { }
	
	n.typ = "group"
	n.transform = transform or vec3(0, 0, 0)
	n.boundary = 0
	n.center = vec3(0, 0, 0)
	
	n.children = { }
	
	return setmetatable(n, {__index = c.meta_group})
end

--sphere node
function c:newSphere(size, transform)
	local n = { }
	
	n.typ = "sphere"
	n.size = size or 1
	n.transform = transform or vec3(0, 0, 0)
	n.boundary = n.size
	
	return setmetatable(n, {__index = c.meta_basic})
end

--box node
function c:newBox(size, transform)
	local n = { }
	
	n.typ = "box"
	n.size = size or vec3(1, 1, 1)
	n.transform = transform or vec3(0, 0, 0)
	n.boundary = n.size:length()
	
	return setmetatable(n, {__index = c.meta_basic})
end

--point node
function c:newPoint(transform)
	local n = { }
	
	n.typ = "point"
	n.transform = transform or vec3(0, 0, 0)
	n.boundary = 0
	
	return setmetatable(n, {__index = c.meta_basic})
end

--segment node
function c:newSegment(a, b)
	local n = { }
	
	n.typ = "segment"
	n.transform = (a + b) / 2
	n.boundary = (a - b):lengthSquared() / 2
	n.a = a - n.transform
	n.b = b - n.transform
	
	return setmetatable(n, {__index = c.meta_basic})
end

--mesh node
function c:newMesh(object, transform)
	if not object then
		return nil
	elseif object.edges then
		--this is a collision object, wrap it into a group
		setmetatable(object, {__index = c.meta_basic})
		local g = self:newGroup(transform)
		g:add(object)
		return g
	elseif object.collisions then
		--object, but with defined collisions
		if object.collisionCount == 1 then
			--only one collision, skip group
			for d,c in pairs(object.collisions) do
				return self:newMesh(c, transform)
			end
		else
			--pack those into a group
			local o = self:newGroup(transform)
			for d,c in pairs(object.collisions) do
				o:add(self:newMesh(c))
			end
			return o
		end
	elseif object.objects then
		--this is an object (with several subobjects)
		local count = 0
		for d,s in pairs(object.objects) do
			count = count + 1
		end
		
		if count == 1 then
			--only one collision, skip group
			for d,s in pairs(object.objects) do
				return self:newMesh(s, transform)
			end
		else
			--pack those into a group
			local o = self:newGroup(transform)
			for d,s in pairs(object.objects) do
				o:add(self:newMesh(s))
			end
			return o
		end
	else
		assert(object.faces, "Object has been cleaned up, collision can not be constructed. Use noCleanup = true argument in object loader!")
		
		--this is a sub object and needs to be converted first
		local n = dream:getCollisionData(object)
		
		--then use the collision to continue
		return self:newMesh(n, transform)
	end
end

--returns the axis aligned normal
local function getBoxNormal(vec)
	local x, y, z = math.abs(vec.x), math.abs(vec.y), math.abs(vec.z)
	local m = math.max(x, y, z)
	if x == m then
		return vec3(vec.x > 0 and 1 or -1, 0.0, 0.0)
	elseif y == m then
		return vec3(0.0, vec.y > 0 and 1 or -1, 0.0)
	else
		return vec3(0.0, 0.0, vec.z > 0 and 1 or -1)
	end
end

--first collides with second
local colliders = {
	point = {
		point = function(a, b, aToB, pos)
			return pos:lengthSquared() < 0.001
		end,
		sphere = function(a, b, aToB, pos)
			return pos:length() < b.size and pos:normalize() or false
		end,
		box = function(a, b, aToB, pos)
			if pos[1] > -b.size[1] / 2 and pos[1] < b.size[1] / 2 and pos[2] > -b.size[2] / 2 and pos[2] < b.size[2] / 2 and pos[3] > -b.size[3] / 2 and pos[3] < b.size[3] / 2 then
				return getBoxNormal(pos)
			else
				return false
			end
		end,
		segment = false,
		mesh = function(a, b, aToB, pos)
			local segment = {pos:normalize() * 10000.0, pos}
			local count = 0
			local normal = vec3(0, 0, 0)
			for d,s in ipairs(b.faces) do
				if c:intersectTriangle(segment, s) then
					count = count + 1
					normal = normal + b.normals[d]
				end
			end
			return count % 2 == 1 and normal:normalize() or false
		end,
	},
	sphere = {
		sphere = function(a, b, aToB, pos)
			return pos:length() < (a.size + b.size) and pos:normalize() or false
		end,
		box = function(a, b, aToB, pos)
			local v = (-b.size/2):max((b.size/2):min(pos))
			if (v - pos):lengthSquared() < a.size * a.size then
				return getBoxNormal(v)
			else
				return false
			end
		end,
		segment = function(a, b, aToB, pos)
			local nearest, val = c:nearestPointToLine(b.a, b.b, pos)
			local length = (b.a - b.b):lengthSquared()
			if (nearest - pos):lengthSquared() < a.size * a.size and val > 0 and val < 1 then
				return (pos - nearest):normalize()
			end
		end,
		mesh = function(a, b, aToB, pos)
			local count = 0
			
			--faces
			local normal = vec3(0, 0, 0)
			for d,s in ipairs(b.faces) do
				if c:intersectTriangle({pos - b.normals[d] * a.size, pos}, s) then
					count = count + 1
					normal = normal + b.normals[d]
				end
			end
			if count % 2 == 1 then
				return normal:normalize()
			end
			
			--edges
			for d,s in ipairs(b.edges) do
				local nearest = c:nearestPointToLine(s[1], s[2], pos)
				if (nearest - pos):lengthSquared() < a.size * a.size then
					return (pos - nearest):normalize()
				end
			end
		end,
	},
	box = {
		--incompatible with rotations
		box = function(a, b, aToB, pos)
			if pos[1] + a.size[1] / 2 > -b.size[1] / 2 and pos[1] - a.size[1] / 2 < b.size[1] / 2 and
				pos[2] + a.size[2] / 2 > -b.size[2] / 2 and pos[2] - a.size[2] / 2 < b.size[2] / 2 and
				pos[3] + a.size[3] / 2 > -b.size[3] / 2 and pos[3] - a.size[3] / 2 < b.size[3] / 2 then
				return getBoxNormal(pos)
			else
				return false
			end
		end,
		segment = false,
		mesh = false,
	},
	segment = {
		mesh = function(a, b, aToB, pos)
			local va = aToB * a.a
			local vb = aToB * a.b
			for d,s in ipairs(b.faces) do
				if c:intersectTriangle({va, vb}, s) then
					return b.normals[d]
				end
			end
		end,
	},
	mesh = {
		mesh = function(a, b, aToB, pos)
			--edge check
			for _, edge in ipairs(a.edges) do
				local va = aToB * edge[1]
				local vb = aToB * edge[2]
				for d,s in ipairs(b.faces) do
					if c:intersectTriangle({va, vb}, s) then
						return b.normals[d]
					end
				end
			end
			
			--random sample
			local v = aToB * a.point
			local segment = {v:normalize() * 10000.0, v}
			local count = 0
			local normal = vec3(0, 0, 0)
			for d,s in ipairs(b.faces) do
				if c:intersectTriangle(segment, s) then
					count = count + 1
					normal = normal + b.normals[d]
				end
			end
			if count % 2 == 1 then
				return normal:normalize()
			end
		end,
	},
}

function c:collide(a, b, bToA, toGlobal)
	--for the sake of performance we keep all return values in A space and only the top call transforms it back into global space
	local root = not bToA
	
	--transform (of b, recursive. TransformInverse therefore transforms "a" into the space of b)
	bToA = bToA and (bToA * getTransform(b.transform)) or (getTransform(b.transform) * getTransform(a.transform):invert())
	aToB = bToA:invert()
	
	--the origin of a in the space of b
	local originOfAInBSpace = vec3(aToB[4], aToB[8], aToB[12])
	
	--boundary check for groups
	if b.center then
		if a.typ == "segment" then
			local b = self:newSphere(b.boundary, b.center)
			if not self:collide(a, b, bToA) then
				return false
			end
		else
			--basic bounding sphere overlap check
			if (originOfAInBSpace - b.center):lengthSquared() > (a.boundary + b.boundary)^2 then
				return false
			end
		end
	end
	
	--collide
	local n
	if colliders[a.typ] and colliders[a.typ][b.typ] then
		local nn = colliders[a.typ][b.typ](a, b, aToB, originOfAInBSpace)
		if nn then
			n = bToA:subm() * nn
		end
	elseif colliders[b.typ] and colliders[b.typ][a.typ] then
		local nn = colliders[b.typ][a.typ](b, a, bToA, vec3(bToA[4], bToA[8], bToA[12]))
		if nn then
			n = aToB:subm() * nn
		end
	else
		--print("unknown", a.typ, b.typ)
	end
	
	--children
	if b.children then
		for d,s in ipairs(b.children) do
			local nn = self:collide(a, s, bToA)
			if nn then
				n = n and (n + nn) or nn
			end
		end
	end
	
	--return normal vector
	if n then
		if root then
			--from A space into global space
			return (getTransform(a.transform):subm() * n):normalize()
		else
			return n:normalize()
		end
	end
end

--returns the point which has the shortest distance to p and lies on the line v, w
function c:nearestPointToLine(v, w, p)
	local wv = w - v
	local l2 = wv:lengthSquared()
	local t = math.max(0, math.min(1, (p - v):dot(wv) / l2))
	return v + t * wv, t
end

--take a ray R and test if it intersects with triangle T
function c:intersectTriangle(R, T)
	--plane normal
	local u = T[2] - T[1]
	local v = T[3] - T[1]
	local n = u:cross(v)
	local dir = R[2] - R[1]
	local b = n:dot(dir)
	
	--check if segment is parallel to plane, only returns true if on it
	if math.abs(b) < 0.000001 then
		return a == 0
	end
	
	local d = n:dot(T[1])
	local r = (d - n:dot(R[1])) / b
	
	--segment to short
	if r < 0.0 or r > 1.0 then
		return false
	end
	
	--get intersect point of segment with triangle plane
	local intersectPoint = R[1] + r * dir;
	
	--is the intersect point inside T?
	if (T[2] - T[1]):cross(intersectPoint - T[1]):dot(n) < 0 then
		return false
	end
	if (T[3] - T[2]):cross(intersectPoint - T[2]):dot(n) < 0 then
		return false
	end
	if (T[1] - T[3]):cross(intersectPoint - T[3]):dot(n) < 0 then
		return false
	end
	
	return intersectPoint
end

--returns physic relevant info
function c:calculateImpact(velocity, normal, elastic, friction)
	local dir = velocity:normalize()
	local speed = velocity:length()
	
	--reflect
	local reflect = dir:reflect(normal)
	
	--slide
	local slide = reflect - (reflect * normal) * normal
	slide = slide:lengthSquared() > 0 and slide:normalize() or slide
	slide = slide * math.max(0, 1.0 - math.abs(dir:dot(normal)))
	
	--final
	local v = reflect * elastic * speed + slide * (1.0 - elastic) * (1.0 - friction) * speed
	
	--impact
	local impact = (velocity - v):length()
	
	return v, impact, reflect, slide
end

--recursively prints a collision tree, its typ, boundary and typ specific extra information
function c:print(o, indent)
	indent = indent or 0
	
	local extra
	if o.typ == "mesh" then
		extra = "mesh with " .. tostring(#o.faces) .. " faces"
	end
	
	print(string.rep("\t", indent) .. o.typ .. " " .. tostring(getTranslate(o.transform)) .. " " .. math.floor(o.boundary*100)/100 ..  (extra and (" (" .. extra .. ")") or ""))
	
	if o.children then
		for d,s in ipairs(o.children) do
			self:print(s, indent+1)
		end
	end
end

return c