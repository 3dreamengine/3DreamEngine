--[[
#DEPRICATED
The collision extension is not recommended due to its extremely low performance and lack of physics.
It remains here as a single file and propably will stay untouched, but error fixes etc are not planned.
If you need physics, check out the blazing fast Box2D extension (physics.lua)
If you want raytracing (ray-mesh collision for shots, view detection, etc) check out the way more suitable raytrace.lua. It works on any mesh and is faster than collision.lua.
--]]

local c = { }

local lib = _3DreamEngine

--get the collision data from a mesh
--it moves the collider to its bounding box center based on its initial transform
function lib:getCollisionData(obj)
	local n = { }
	
	--data required by the collision extension
	n.typ = "mesh"
	n.boundary = 0
	n.name = obj.name
	n.group = obj.group
	
	--offset, a transformation will be directly applied
	n.transform = obj.boundingBox and obj.boundingBox.center or vec3(0, 0, 0)
	
	if obj.transform then
		n.transform = obj.transform * n.transform
	end
	
	n.transformInverse = -n.transform
	
	--data
	n.faces = { }
	n.normals = { }
	n.edges = { }
	n.point = vec3(0, 0, 0)
	
	--transform vertices
	local vertices = { }
	for d,s in ipairs(obj.vertices) do
		vertices[d] = (obj.transform and obj.transform * vec3(s) or vec3(s)) - n.transform
	end
	
	local hashes = { }
	for d,s in ipairs(obj.faces) do
		--vertices
		local a = vertices[s[1]]
		local b = vertices[s[2]]
		local c = vertices[s[3]]
		
		--edges
		for i = 1, 3 do
			local n1 = s[i % 3 + 1]
			local n2 = s[(i+1) % 3 + 1]
			
			local id = math.min(n1, n2) * 9999 + math.max(n1, n2)
			if not hashes[id] then
				table.insert(n.edges, {vertices[n1], vertices[n2]})
				hashes[id] = true
			end
		end
		
		--face normal
		local normal = (b-a):cross(c-a):normalize()
		table.insert(n.normals, normal)
		
		n.point = a
		
		--boundary
		n.boundary = math.max(n.boundary, a:length(), b:length(), c:length())
		
		--face
		table.insert(n.faces, {a, b, c})
	end
	
	return n
end

local I = mat4:getIdentity()
local Z = vec3()

--get the vec3 offset of a transform object (which can be a mat4 or vec3)
local function getTranslate(s)
	return s.type == "vec3" and s or vec3(s[4], s[8], s[12])
end
local function getTransform(x, y, z)
	if x then
		return y and vec3(x, y, z) or x
	else
		return Z
	end
end
local function getInverseTransform(x, y, z)
	if x then
		return y and vec3(-x, -y, -z) or x.type == "mat4" and x:invert() or -x
	else
		return Z
	end
end
local function applyTransform(t, v)
	return t.type == "mat4" and (t * v) or (t + v)
end

--group meta
c.meta_group = {
	--add object to group
	add = function(self, o)
		if not o then
			return
		end
		self:addFast(o)
		self:apply()
	end,
	
	addFast = function(self, o)
		if not o then
			return
		end
		table.insert(self.children, o)
		o.parent = self
	end,
	
	--remove object from group
	remove = function(self, o)
		o.parent = nil
		for d,s in ipairs(self.children) do
			if s == o then
				table.remove(self.children, d)
				self:apply()
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
			if s.center then
				self.center = self.center + s.center
			end
		end
		self.center = self.center / #self.children
		
		--get max boundary size
		self.boundary = 0
		for d,s in ipairs(self.children) do
			local transform = getTranslate(s.transform)
			if s.center then
				transform = transform + s.center
			end
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
			children = children,
		}
	end,
	
	--move object, recreating boundaries for parents
	moveTo = function(self, x, y, z)
		self.transform = getTransform(x, y, z)
		self.transformInverse = getInverseTransform(x, y, z)
		
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
	moveTo = function(self, x, y, z)
		self.transform = getTransform(x)
		self.transformInverse = getInverseTransform(x)
		
		if self.parent then
			self.parent:apply()
		end
	end
}

--group node
function c:newGroup(transform)
	local n = { }
	
	n.typ = "group"
	n.transform = getTransform(transform)
	n.transformInverse = getInverseTransform(transform)
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
	n.transform = getTransform(transform)
	n.transformInverse = getInverseTransform(transform)
	n.boundary = n.size
	
	return setmetatable(n, {__index = c.meta_basic})
end

--box node
function c:newBox(size, transform)
	local n = { }
	
	n.typ = "box"
	n.size = size or vec3(1, 1, 1)
	n.transform = getTransform(transform)
	n.transformInverse = getInverseTransform(transform)
	n.boundary = n.size:length()
	
	return setmetatable(n, {__index = c.meta_basic})
end

--point node
function c:newPoint(transform)
	local n = { }
	
	n.typ = "point"
	n.transform = getTransform(transform)
	n.transformInverse = getInverseTransform(transform)
	n.boundary = 0
	
	return setmetatable(n, {__index = c.meta_basic})
end

--segment node
function c:newSegment(a, b)
	local n = { }
	local center = (a + b) / 2
	
	n.typ = "segment"
	n.transform = getTransform(center)
	n.transformInverse = getInverseTransform(center)
	n.boundary = (a - b):lengthSquared() / 2
	n.a = a - center
	n.b = b - center
	
	return setmetatable(n, {__index = c.meta_basic})
end

--mesh node
function c:newMesh(object, transform)
	if not object then
		return nil
	elseif object.point then
		--this is a collision object, wrap it into a group
		setmetatable(object, {__index = c.meta_basic})
		local g = self:newGroup(object.linkTransform or transform)
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
				o:addFast(self:newMesh(c))
			end
			o:apply()
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
		assert(object.faces and object.vertices, "Object has been cleaned up or is invalid, 'faces' and 'vertices' buffers are required!")
		
		--this is a sub object and needs to be converted first
		local n = lib:getCollisionData(object)
		
		--then use the collision to continue
		return self:newMesh(n, transform)
	end
end

--returns the point which has the shortest distance to p and lies on the line v, w
local function nearestPointToLine(v, w, p)
	local wv = w - v
	local l2 = wv:lengthSquared()
	local t = math.max(0, math.min(1, (p - v):dot(wv) / l2))
	return v + t * wv
end

--take a ray R and test if it intersects with triangle T
local function intersectTriangle(Ra, Rb, T)
	--plane normal
	local u = T[2] - T[1]
	local v = T[3] - T[1]
	local n = u:cross(v)
	local dir = Rb - Ra
	local b = n:dot(dir)
	
	--check if segment is parallel to plane, only returns true if on it
	if math.abs(b) < 0.000001 then
		return a == 0
	end
	
	local d = n:dot(T[1])
	local r = (d - n:dot(Ra)) / b
	
	--segment to short
	if r < 0.0 or r > 1.0 then
		return false
	end
	
	--get intersect point of segment with triangle plane
	local intersectPoint = Ra + r * dir;
	
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
		point = function(a, b, aToB, pos, fast)
			if pos:lengthSquared() < 0.001 then
				return pos
			end
		end,
		sphere = function(a, b, aToB, pos, fast)
			if pos:length() < b.size then
				return pos
			end
		end,
		box = function(a, b, aToB, pos, fast)
			if pos[1] > -b.size[1] / 2 and pos[1] < b.size[1] / 2 and pos[2] > -b.size[2] / 2 and pos[2] < b.size[2] / 2 and pos[3] > -b.size[3] / 2 and pos[3] < b.size[3] / 2 then
				return getBoxNormal(pos)
			end
		end,
		segment = false,
		mesh = function(a, b, aToB, pos, fast)
			local segment = {pos:normalize() * 10000.0, pos}
			local count = 0
			local normal = vec3(0, 0, 0)
			local avgPos = vec3(0, 0, 0)
			for d,s in ipairs(b.faces) do
				local p = intersectTriangle(segment, s)
				if p then
					if fast then
						return b.normals[d], p
					end
					count = count + 1
					normal = normal + b.normals[d]
					avgPos = avgPos + p
				end
			end
			if count % 2 == 1 then
				return normal, avgPos / count
			end
		end,
	},
	sphere = {
		sphere = function(a, b, aToB, pos, fast)
			if pos:length() < a.size + b.size then
				return pos
			end
		end,
		box = function(a, b, aToB, pos, fast)
			local v = (-b.size/2):max((b.size/2):min(pos))
			if (v - pos):lengthSquared() < a.size * a.size then
				return getBoxNormal(v), v
			end
		end,
		segment = function(a, b, aToB, pos, fast)
			local nearest = nearestPointToLine(b.a, b.b, pos)
			local length = (b.a - b.b):lengthSquared()
			if (nearest - pos):lengthSquared() < a.size * a.size then
				return (pos - nearest):normalize(), nearest
			end
		end,
		mesh = function(a, b, aToB, pos, fast)
			--faces
			local count = 0
			local normal = vec3(0, 0, 0)
			local avgPos = vec3(0, 0, 0)
			for d,s in ipairs(b.faces) do
				local p = intersectTriangle(pos - b.normals[d] * a.size, pos, s)
				if p then
					if fast then
						return b.normals[d], p
					end
					count = count + 1
					normal = normal + b.normals[d]
					avgPos = avgPos + p
				end
			end
			
			if count > 0 then
				return normal, avgPos / count
			end
			
			--edges
			for d,s in ipairs(b.edges) do
				local nearest = nearestPointToLine(s[1], s[2], pos)
				if (nearest - pos):lengthSquared() < a.size * a.size then
					if fast then
						return pos - nearest, nearest
					end
					count = count + 1
					normal = normal + (pos - nearest)
					avgPos = avgPos + nearest
				end
			end
			if count > 0 then
				return normal, avgPos / count
			end
		end,
	},
	box = {
		--incompatible with rotations
		box = function(a, b, aToB, pos, fast)
			if pos[1] + a.size[1] / 2 > -b.size[1] / 2 and pos[1] - a.size[1] / 2 < b.size[1] / 2 and
				pos[2] + a.size[2] / 2 > -b.size[2] / 2 and pos[2] - a.size[2] / 2 < b.size[2] / 2 and
				pos[3] + a.size[3] / 2 > -b.size[3] / 2 and pos[3] - a.size[3] / 2 < b.size[3] / 2 then
				return getBoxNormal(pos)
			end
		end,
	},
	segment = {
		mesh = function(a, b, aToB, pos, fast)
			local va = applyTransform(aToB, a.a)
			local vb = applyTransform(aToB, a.b)
			
			--other than usual segment-mesh collisions we return nearest point to a
			local best = math.huge
			local normal, pos
			
			for d,s in ipairs(b.faces) do
				local p = intersectTriangle(va, vb, s)
				if p then
					if fast then
						return b.normals[d], p
					else
						local dist = (p - va):lengthSquared()
						if dist < best then
							best = dist
							normal = b.normals[d]
							pos = p
						end
					end
				end
			end
			
			return normal, pos
		end,
	},
	mesh = {
		mesh = function(a, b, aToB, pos, fast)
			--edge check
			--because of quadratic complexity fast mode is always used
			for _, edge in ipairs(a.edges) do
				local va = applyTransform(edge[1])
				local vb = applyTransform(edge[2])
				for d,s in ipairs(b.faces) do
					if intersectTriangle(va, vb, s) then
						return b.normals[d]
					end
				end
			end
			
			--random sample in case mesh a is in mesh b (or vice verta)
			local v = applyTransform(aToB, a.point)
			local sa = v:normalize() * 10000.0
			local sb = v
			local count = 0
			local normal = vec3(0, 0, 0)
			local avgPos = vec3(0, 0, 0)
			for d,s in ipairs(b.faces) do
				local p = intersectTriangle(sa, sb, s)
				if p then
					count = count + 1
					normal = normal + b.normals[d]
					avgPos = avgPos + p
				end
			end
			if count % 2 == 1 then
				return normal, avgPos / count
			end
		end,
	},
}

--returns the collisions of the last check
local collisions = { }
function c:getCollisions()
	return collisions
end

function c:collide(a, b, fast, bToA, aToB)
	--for the sake of performance we keep all return values in A space and only the top call transforms it back into global space
	local root = not bToA
	if root then
		collisions = { }
	end
	
	if root then
		--unpack a in case its a group
		if a.children then
			aToB = transformA:affineAdd(a.children[1].transform)
			bToA = transformAInverse:affineAdd(a.children[1].transformInverse)
			a = a.children[1]
		else
			aToB = getTransform(a.transform)
			bToA = getTransform(a.transformInverse)
		end
	end
	
	--aToB = getTransform(b.transformInverse) * aToB
	aToB = b.transformInverse:affineAdd(aToB)
	
	local earlyTransform = b.center and a.typ == "segment"
	if earlyTransform then
		bToA = bToA:affineAdd(b.transform)
	end
	
	--the origin of a in the space of b
	local originOfAInBSpace = aToB.type == "mat4" and vec3(aToB[4], aToB[8], aToB[12]) or aToB
	
	--boundary check for groups
	if b.center then
		if a.typ == "segment" then
			local c = self:newSphere(b.boundary)
			if not colliders[c.typ][a.typ](c, a, bToA, applyTransform(bToA, b.center), true) then
				return false
			end
		else
			--basic bounding sphere overlap check
			if (originOfAInBSpace - b.center):lengthSquared() > (a.boundary + b.boundary)^2 then
				return false
			end
		end
	end
	
	local firstColl = colliders[a.typ] and colliders[a.typ][b.typ]
	local maySkipTransform = firstColl and fast
	if not earlyTransform and not maySkipTransform then
		bToA = bToA:affineAdd(b.transform)
	end
	
	--collide
	if firstColl then
		local normal, pos = firstColl(a, b, aToB, originOfAInBSpace, fast)
		if normal then
			if fast then
				return true
			end
			normal = (bToA.type == "mat4" and bToA:subm() * normal or normal):normalize()
			pos = applyTransform(bToA, pos or originOfAInBSpace)
			table.insert(collisions, {normal, pos, b})
		end
	elseif colliders[b.typ] and colliders[b.typ][a.typ] then
		local originOfBInASpace = bToA.type == "mat4" and vec3(bToA[4], bToA[8], bToA[12]) or bToA
		local normal, pos = colliders[b.typ][a.typ](b, a, bToA, originOfBInASpace, fast)
		if normal then
			if fast then
				return true
			end
			normal = (aToB.type == "mat4" and aToB:subm() * normal or normal):normalize()
			pos = applyTransform(aToB, pos or originOfBInASpace)
			table.insert(collisions, {normal, pos, b})
		end
	else
		--print("unknown", a.typ, b.typ)
	end
	
	--children
	if b.children then
		if not earlyTransform and maySkipTransform then
			bToA = bToA:affineAdd(b.transform)
		end
		for d,s in ipairs(b.children) do
			local done = self:collide(a, s, fast, bToA, aToB)
			if done then
				return true
			end
		end
	end
	
	--return false in fast mode because at this point no collision has occured
	if fast then
		return false
	end
	
	--root, transform all collisions to global space and calculate average normal and position
	if root then
		if collisions[1] then
			local normal = vec3(0, 0, 0)
			local pos = vec3(0, 0, 0)
			
			--transform from A to global
			local m = getTransform(a.transform)
			local subm = m.type == "mat4" and m:subm()
			
			--transform and average values
			for d,s in ipairs(collisions) do
				if a.transform.type == "mat4" then
					s[1] = a.transform:subm() * s[1]
				end
				
				s[2] = applyTransform(a.transform, s[2])
				
				normal = normal + s[1]
				pos = pos + s[2]
			end
			return normal:normalize(), pos / #collisions
		else
			return false
		end
	end
end

--returns physic relevant info
function c:calculateImpact(velocity, normal, elastic, friction)
	if velocity:lengthSquared() == 0 then
		return vec3(), 0, vec3(), vec3()
	end
	
	local dir = velocity:normalize()
	local speed = velocity:length()
	
	--reflect
	local reflect = dir:reflect(normal)
	
	--slide
	local slide = reflect - (reflect * normal) * normal
	slide = slide:lengthSquared() > 0 and slide:normalize() or slide
	local directImpact = math.max(0, dir:dot(-normal))
	
	--final
	local final = (reflect * elastic + slide * (1.0 - elastic) * (1.0 - friction) * (1.0 - directImpact)) * speed
	
	--impact
	local impact = (velocity - final):length()
	
	return final, impact, reflect, slide
end

--recursively prints a collision tree, its typ, boundary and typ specific extra information
function c:print(o, indent)
	indent = indent or 0
	
	local extra
	if o.typ == "mesh" then
		extra = "mesh with " .. tostring(#o.faces) .. " faces"
	end
	
	print(string.rep("\t", indent) .. o.typ .. " size: " .. math.floor(o.boundary*100)/100 .. " " .. tostring(o.transform.type) .. (extra and (" (" .. extra .. ")") or ""))
	
	if o.children then
		for d,s in ipairs(o.children) do
			self:print(s, indent+1)
		end
	end
end

return c