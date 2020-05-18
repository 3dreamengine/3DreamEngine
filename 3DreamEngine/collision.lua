local c = { }

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
		self.boundary = 0
		for d,s in ipairs(self.children) do
			local transform = c:gettransform(s.transform)
			local size = s.transform == "mat4" and (s.transform * vec3(0, 0, s.boundary) - transform):length() or s.boundary
			self.boundary = math.max(self.boundary, transform:length() + size)
		end
		
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
function c:newGroup(transform, transform)
	local n = { }
	
	n.typ = "group"
	n.transform = transform or vec3(0, 0, 0)
	n.boundary = 0
	
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

--mesh node
function c:newMesh(object, subObject, transform)
	if not object then
		return nil
	elseif object.edges then
		local n = { }
		
		n.typ = "mesh"
		n.name = object.name
		n.transform = transform or vec3(0, 0, 0)
		n.boundary = object.boundary
		
		n.faces = object.faces
		n.normals = object.normals
		n.edges = object.edges
		n.vertices = object.vertices
		n.point = object.point
		
		return n
	elseif object.collisions then
		if subObject then
			return self:newMesh(object.collisions[subObject], subObject, transform)
		else
			if object.collisionCount == 1 then
				for d,c in pairs(object.collisions) do
					return self:newMesh(c, subObject, transform)
				end
			else
				local o = self:newGroup(transform)
				for d,c in pairs(object.collisions) do
					o:add(self:newMesh(c, subObject))
				end
				return o
			end
		end
	elseif object.objects then
		if subObject then
			return self:newMesh(object.objects[subObject], subObject, transform)
		else
			local count = 0
			for d,s in pairs(object.objects) do
				count = count + 1
			end
			
			if count == 1 then
				for d,s in pairs(object.objects) do
					return self:newMesh(s, subObject, transform)
				end
			else
				local o = self:newGroup(transform)
				for d,s in pairs(object.objects) do
					o:add(self:newMesh(s, subObject))
				end
				return o
			end
		end
	else
		local n = { }
		
		n.typ = "mesh"
		n.name = object.name
		n.transform = transform or vec3(0, 0, 0)
		n.boundary = 0
		
		assert(object.faces, "Object has been cleaned up, collision can be reconstructed. Use noCleanup = true argument in object loader!")
		
		n.faces = { }
		n.normals = { }
		n.edges = { }
		n.point = vec3(0, 0, 0)
		
		local function hash(a, b)
			return math.min(a, b) * 9999 + math.max(a, b)
		end
		
		local hashes = { }
		local f = object.final
		
		for d,s in ipairs(object.faces) do
			local a, b, c = f[s[1]], f[s[2]], f[s[3]]
			
			n.point = a
			
			--face normal
			table.insert(n.normals, vec3(a[5]+b[5]+c[5], a[6]+b[6]+c[6], a[7]+b[7]+c[7]):normalize())
			
			a = vec3(a[1], a[2], a[3])
			b = vec3(b[1], b[2], b[3])
			c = vec3(c[1], c[2], c[3])
			
			--boundary
			n.boundary = math.max(n.boundary, a:length(), b:length(), c:length())
			
			--face
			table.insert(n.faces, {a, b, c})
			
			--edges
			local id
			id = hash(s[1], s[2])
			if not hashes[id] then
				table.insert(n.edges, {a, b})
				hashes[id] = true
			end
			
			id = hash(s[1], s[3])
			if not hashes[id] then
				table.insert(n.edges, {a,c })
				hashes[id] = true
			end
			
			id = hash(s[2], s[3])
			if not hashes[id] then
				table.insert(n.edges, {b, c})
				hashes[id] = true
			end
		end
		
		return setmetatable(n, {__index = c.meta_basic})
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

local function transformVec(v, transform)
	local v2 = transform and (transform * v) or v
	return v2.type == "mat4" and (v2 * vec3(0, 0, 0)) or v2
end

--first collides with second
local colliders = {
	point = {
		point = function(a, b, transform, transformInverse)
			local pos = transformVec(a.transform, transformInverse)
			return pos:lengthSquared() < 0.001
		end,
		sphere = function(a, b, transform, transformInverse)
			local vec = transformVec(a.transform, transformInverse)
			return vec:length() < b.size and vec:normalize() or false
		end,
		box = function(a, b, transform, transformInverse)
			local pos = transformVec(a.transform, transformInverse)
			if pos[1] > -b.size[1] / 2 and pos[1] < b.size[1] / 2 and pos[2] > -b.size[2] / 2 and pos[2] < b.size[2] / 2 and pos[3] > -b.size[3] / 2 and pos[3] < b.size[3] / 2 then
				return getBoxNormal(pos)
			else
				return false
			end
		end,
		segment = false,
		mesh = function(a, b, transform, transformInverse)
			local pos = transformVec(a.transform, transformInverse)
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
		point = function(a, b, transform, transformInverse)
			local vec = transformVec(a.transform, transformInverse)
			return vec:length() < a.size and vec:normalize() or false
		end,
		sphere = function(a, b, transform, transformInverse)
			local vec = transformVec(a.transform, transformInverse)
			return vec:length() < (a.size + b.size) and vec:normalize() or false
		end,
		box = function(a, b, transform, transformInverse)
			local pos = transformVec(a.transform, transformInverse)
			local v = (-b.size/2):max((b.size/2):min(pos))
			if (v - pos):lengthSquared() < a.size * a.size then
				return getBoxNormal(v)
			else
				return false
			end
		end,
		segment = false,
		mesh = function(a, b, transform, transformInverse)
			local pos = transformVec(a.transform, transformInverse)
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
		point = function(a, b, transform, transformInverse)
			--using inverse approach and transform point into axis aligned coords
			local pos = transformVec(b.transform, transformInverse, transform)
			if pos[1] > -a.size[1] / 2 and pos[1] < a.size[1] / 2 and pos[2] > -a.size[2] / 2 and pos[2] < a.size[2] / 2 and pos[3] > -a.size[3] / 2 and pos[3] < a.size[3] / 2 then
				return getBoxNormal(pos)
			else
				return false
			end
		end,
		sphere = function(a, b, transform, transformInverse)
			--using inverse approach and transform point into axis aligned coords
			local pos = transformVec(b.transform, transformInverse, transform)
			local v = (-a.size/2):max((a.size/2):min(pos))
			if (v - pos):lengthSquared() < b.size * b.size then
				return -v:normalize()
			else
				return false
			end
		end,
		box = function(a, b, transform, transformInverse)
			if transform then
				--transformation not possible and will be skipped
			else
				local pos = a.transform - b.transform + transform
				if pos[1] + a.size[1] / 2 > -b.size[1] / 2 and pos[1] - a.size[1] / 2 < b.size[1] / 2 and
					pos[2] + a.size[2] / 2 > -b.size[2] / 2 and pos[2] - a.size[2] / 2 < b.size[2] / 2 and
					pos[3] + a.size[3] / 2 > -b.size[3] / 2 and pos[3] - a.size[3] / 2 < b.size[3] / 2 then
					return getBoxNormal(pos)
				else
					return false
				end
			end
		end,
		segment = false,
		mesh = false,
	},
	segment = {
		
	},
	mesh = {
		mesh = function(a, b, transform, transformInverse)
			--edge check
			for _, edge in ipairs(a.edges) do
				local e1, e2
				if a.transform.type == "mat4" then
					e1 = a.transform * edge[1]
					e2 = a.transform * edge[2]
				else
					e1 = edge[1] + a.transform
					e2 = edge[2] + a.transform
				end
				
				local va = transformVec(e1, transformInverse)
				local vb = transformVec(e2, transformInverse)
				for d,s in ipairs(b.faces) do
					if c:intersectTriangle({va, vb}, s) then
						return b.normals[d]
					end
				end
			end
			
			--random sample
			local r
			if a.transform.type == "mat4" then
				r = a.transform * a.point
			else
				r = a.point + a.transform
			end
			
			local v = transformVec(r, transformInverse)
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

function c:collide(a, b, transform, transformInverse)
	--transform
	local t = b.transform.type == "mat4" and b.transform or mat4:getTranslate(b.transform)
	transform = transform and (t * transform) or t
	transformInverse = transformInverse and (t:invert() * transformInverse) or t:invert()
	
	--boundary skip
	local pos = transformVec(a.transform, transformInverse)
	if pos:lengthSquared() > (a.boundary + b.boundary)^2 then
		return false
	end
	
	--collide
	local n
	if colliders[a.typ] and colliders[a.typ][b.typ] then
		local nn = colliders[a.typ][b.typ](a, b, transform, transformInverse)
		if nn then
			n = n and (n + nn) or nn
		end
	elseif colliders[b.typ] and colliders[b.typ][a.typ] then
		local nn = colliders[b.typ][a.typ](b, a, transformInverse, transform)
		if nn then
			n = n and (n + nn) or nn
		end
	else
		--print("unknown", a.typ, b.typ)
	end
	
	--children
	if b.children then
		for d,s in ipairs(b.children) do
			local nn = self:collide(a, s, transform, transformInverse)
			if nn then
				n = n and (n + nn) or nn
			end
		end
	end
	
	return n and (transform:subm() * n):normalize() or false
end

function c:gettransform(s)
	return s.type == "mat4" and (s * vec3(0, 0, 0)) or s
end

function c:nearestPointToLine(v, w, p)
	local wv = w - v
	local l2 = wv:lengthSquared()
	local t = math.max(0, math.min(1, (p - v):dot(wv) / l2))
	return v + t * wv
end

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

function c:print(o, indent)
	indent = indent or 0
	
	local extra
	if o.typ == "mesh" then
		extra = tostring(o.name) .. " with " .. tostring(#o.faces) .. " faces"
	end
	
	print(string.rep("\t", indent) .. o.typ .. (extra and (" (" .. extra .. ")") or ""))
	
	if o.children then
		for d,s in ipairs(o.children) do
			self:print(s, indent+1)
		end
	end
end

return c