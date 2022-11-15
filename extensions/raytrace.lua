--[[
#raytrace extension
Takes a non-cleaned (face map still present) mesh, creates a BSP-tree,
uses the objects bounding box as a pre-test, transforms accordingly to the objects transformations
and returns either a boolean or, slightly slower, a position of intersection.
While rather fast, it is recommended to use a lower poly approximation mesh whenever possible.

triangle testing method:
Doug Baldwin and Michael Weber, Fast Ray-Triangle Intersections by Coordinate Transformation, Journal of Computer Graphics Techniques (JCGT), vol. 5, no. 3, 39-49, 2016
http://jcgt.org/published/0005/03/03/
--]]

--smallest subset after partitioning
local threshold = 50

--search result
local nearestT, nearestU, nearestV, nearestFace, nearestMesh

--build the transformation matrices for each triangle
local function buildMatrices(mesh)
	local matrices = { }
	for i, face in mesh.faces:ipairs() do
		--vertices
		local a = mesh.vertices:getVector(face[1])
		local b = mesh.vertices:getVector(face[2])
		local c = mesh.vertices:getVector(face[3])
		
		--edges and normal
		local e1 = b - a
		local e2 = c - a
		local n = e1:cross(e2)
		
		--for each axis a transformation matrix
		local mn = n:abs()
		if mn.x > mn.y and mn.x > mn.z then
			matrices[i] = {
				0, e2.z / n.x, -e2.y / n.x, c:cross(a).x / n.x,
				0, -e1.z / n.x, e1.y / n.x, -(b:cross(a)).x / n.x,
				1, n.y / n.x, n.z / n.x, -n:dot(a) / n.x,
				face
			}
		elseif mn.y > mn.x and mn.y > mn.z then
			matrices[i] = {
				-e2.z / n.y, 0, e2.x / n.y, c:cross(a).y / n.y,
				e1.z / n.y, 0, -e1.x / n.y, -b:cross(a).y / n.y,
				n.x / n.y, 1, n.z / n.y, -n:dot(a) / n.y,
				face
			}
		else
			matrices[i] = {
				e2.y / n.z, -e2.x / n.z, 0, c:cross(a).z / n.z,
				-e1.y / n.z, e1.x / n.z, 0, -b:cross(a).z / n.z,
				n.x / n.z, n.y / n.z, 1, -n:dot(a) / n.z,
				face
			}
		end
	end
	return matrices
end

--build the binary partition tree with transformation matrix lists as leafs
local normals = { vec3(1, 0, 0), vec3(0, 1, 0), vec3(0, 0, 1) }
local function buildTree(vertices, list, depth)
	--get origin
	local center = vec3(0, 0, 0)
	for _, m in ipairs(list) do
		local faceIndex = m[13]
		local a = vertices:getVector(faceIndex[1])
		local b = vertices:getVector(faceIndex[2])
		local c = vertices:getVector(faceIndex[3])
		center = center + a + b + c
	end
	center = center / #list / 3
	
	--get normal
	local normal = normals[depth % 3 + 1]
	
	--split
	local left = { }
	local right = { }
	for _, m in ipairs(list) do
		local faceIndex = m[13]
		local a = normal:dot(vertices:getVector(faceIndex[1]) - center) > 0
		local b = normal:dot(vertices:getVector(faceIndex[2]) - center) > 0
		local c = normal:dot(vertices:getVector(faceIndex[3]) - center) > 0
		
		if a == b and b == c and c == a then
			if a then
				--left side
				table.insert(left, m)
			else
				--right side
				table.insert(right, m)
			end
		else
			--both side
			table.insert(left, m)
			table.insert(right, m)
		end
	end
	
	--failed to split, leaf node
	if #left >= #list - threshold or #right >= #list - threshold then
		return list
	end
	
	--new node
	local node = { }
	node.center = center
	node.normal = normal
	node.left = buildTree(vertices, left, depth + 1)
	node.right = buildTree(vertices, right, depth + 1)
	return node
end

--returns true of the ray hits the triangle
local function triangleCheck(o, d, m)
	--intersection
	local oz = m[9] * o[1] + m[10] * o[2] + m[11] * o[3] + m[12]
	local dz = m[9] * d[1] + m[10] * d[2] + m[11] * d[3]
	local t = -oz / dz
	if t < 0 or t > nearestT then
		return
	end
	
	--barycentric u
	local ox = m[1] * o[1] + m[2] * o[2] + m[3] * o[3] + m[4]
	local dx = m[1] * d[1] + m[2] * d[2] + m[3] * d[3]
	local u = ox + t * dx
	if u < 0 or u > 1 then
		return
	end
	
	--barycentric v
	local oy = m[5] * o[1] + m[6] * o[2] + m[7] * o[3] + m[8]
	local dy = m[5] * d[1] + m[6] * d[2] + m[7] * d[3]
	local v = oy + t * dy
	
	if v >= 0 and u + v <= 1 then
		nearestT = t
		nearestU = u
		nearestV = v
		nearestFace = m[13]
	end
end

--performs a boolean raytrace on given origin and direction vector
local function raytraceTree(origin, direction, node)
	if node.center then
		--on which side is the line
		local a = node.normal:dot(origin - node.center) > 0
		local b = node.normal:dot(origin + direction - node.center) > 0
		if a == b then
			if a then
				raytraceTree(origin, direction, node.left)
			else
				raytraceTree(origin, direction, node.right)
			end
		else
			--both sides
			raytraceTree(origin, direction, node.left)
			raytraceTree(origin, direction, node.right)
		end
	else
		--leaf node, go through all possible triangles
		for _, m in ipairs(node) do
			triangleCheck(origin, direction, m)
		end
	end
end

--returns the point with the minimal distance between point p and line ab
local function nearestPointToLine(a, b, p)
	local ab = b - a
	local l2 = ab:lengthSquared()
	local t = math.max(0, math.min(1, (p - a):dot(ab) / l2))
	return a + t * ab
end

local function raytraceMesh(mesh, localOrigin, localDirection)
	--bounding box check
	local center = mesh.boundingBox.center
	local nearest = nearestPointToLine(localOrigin, localOrigin + localDirection, center)
	if (nearest - center):lengthSquared() > mesh.boundingBox.size ^ 2 then
		return false
	end
	
	--build acceleration structures
	if not mesh.raytraceTree then
		mesh.raytraceTree = buildTree(mesh.vertices, buildMatrices(mesh), 1)
	end
	
	--raytrace
	local oldT = nearestT
	local oldF = nearestFace
	raytraceTree(localOrigin, localDirection, mesh.raytraceTree)
	if oldT ~= nearestT or oldF ~= nearestFace then
		nearestMesh = mesh
		return { }
	end
end

local function raytraceObject(object, localOrigin, localDirection, onlyRaytraceMeshes)
	--object transform
	if object.transform then
		local m = object:getInvertedTransform()
		localOrigin = m * localOrigin
		localDirection = vec3({
			m[1] * localDirection[1] + m[2] * localDirection[2] + m[3] * localDirection[3],
			m[5] * localDirection[1] + m[6] * localDirection[2] + m[7] * localDirection[3],
			m[9] * localDirection[1] + m[10] * localDirection[2] + m[11] * localDirection[3],
		})
	end
	
	--for all meshes
	local transforms
	for _, mesh in pairs(onlyRaytraceMeshes and object.raytraceMeshes or object.meshes) do
		if mesh.vertices and mesh.faces then
			transforms = raytraceMesh(mesh, localOrigin, localDirection) or transforms
		end
	end
	
	--for all objects
	for _, o in pairs(object.objects) do
		transforms = raytraceObject(o, localOrigin, localDirection, onlyRaytraceMeshes) or transforms
	end
	
	--on the way back, store transformation matrices
	if transforms and object.transform then
		table.insert(transforms, object.transform)
	end
	
	return transforms
end

---@class DreamRaytraceResult
local raytraceResult = { }
local meta = { __index = raytraceResult }

function raytraceResult:getDistance()
	return self.t
end

function raytraceResult:getUV()
	return self.u, self.v
end

function raytraceResult:getFace()
	return self.face
end

function raytraceResult:getMesh()
	return self.mesh
end

function raytraceResult:getPosition()
	return self.position
end

function raytraceResult:getNormal()
	if not self.normal then
		if self.mesh.normals then
			local a = self.mesh.normals:getVector(self.face[1])
			local b = self.mesh.normals:getVector(self.face[2])
			local c = self.mesh.normals:getVector(self.face[3])
			self.normal = a * self.u + b * self.v + c * (1.0 - self.u - self.v)
		else
			local a = self.mesh.vertices:getVector(self.face[1])
			local b = self.mesh.vertices:getVector(self.face[2])
			local c = self.mesh.vertices:getVector(self.face[3])
			self.normal = (b - a):cross(c - a)
		end
		
		--convert back into global position
		if self.transforms then
			for i = 1, #self.transforms do
				self.normal = self.transforms[i]:subm() * self.normal
			end
		end
		
		self.normal = self.normal:normalize()
	end
	return self.normal
end

---@class DreamRaytracer
local raytracer = { }

---Trace a ray, return closest collision
---@param object DreamObject
---@param origin "vec3"
---@param direction "vec3"
---@param onlyRaytraceMeshes boolean @ only use raytrace meshes
---@return DreamRaytraceResult | "false"
function raytracer:cast(object, origin, direction, onlyRaytraceMeshes)
	--clear search
	nearestT, nearestU, nearestV, nearestFace, nearestMesh = 1, false, false, false, false
	
	--search
	local transforms = raytraceObject(object, origin, direction, onlyRaytraceMeshes)
	
	--pack
	return nearestU and setmetatable({
		t = nearestT,
		u = nearestU,
		v = nearestV,
		face = nearestFace,
		mesh = nearestMesh,
		transforms = transforms,
		position = origin + nearestT * direction
	}, meta) or false
end

return raytracer