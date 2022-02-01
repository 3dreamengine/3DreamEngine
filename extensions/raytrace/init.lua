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

local maxT, maxU, maxV, maxF

--build the transformation matrices for each triangle
local function buildMatrices(object)
	local matrices = { }
	for d,tri in ipairs(object.faces) do
		--vertices
		local a = vec3(object.vertices[tri[1]])
		local b = vec3(object.vertices[tri[2]])
		local c = vec3(object.vertices[tri[3]])
		
		--edges and normal
		local e1 = b - a
		local e2 = c - a
		local n = e1:cross(e2)
		
		--for each axis a transformation matrix
		local mn = n:abs()
		if mn.x > mn.y and mn.x > mn.z then
			matrices[d] = {
				0, e2.z / n.x, -e2.y / n.x, c:cross(a).x / n.x,
				0, -e1.z / n.x, e1.y / n.x, -(b:cross(a)).x / n.x,
				1, n.y / n.x, n.z / n.x, -n:dot(a) / n.x,
				tri
			}
		elseif mn.y > mn.x and mn.y > mn.z then
			matrices[d] = {
				-e2.z / n.y, 0, e2.x / n.y, c:cross(a).y / n.y,
				e1.z / n.y, 0, -e1.x / n.y, -b:cross(a).y / n.y,
				n.x / n.y, 1, n.z / n.y, -n:dot(a) / n.y,
				tri
			}
		else
			matrices[d] = {
				e2.y / n.z, -e2.x / n.z, 0, c:cross(a).z / n.z,
				-e1.y / n.z, e1.x / n.z, 0, -b:cross(a).z / n.z,
				n.x / n.z, n.y / n.z, 1, -n:dot(a) / n.z,
				tri
			}
		end
	end
	return matrices
end

--build the binary partition tree with transformation matrix lists as leafs
local normals = {vec3(1, 0, 0), vec3(0, 1, 0), vec3(0, 0, 1)}
local function buildTree(vertices, list, depth)
	--get origin
	local pos = vec3(0, 0, 0)
	for d,s in ipairs(list) do
		local tri = s[13]
		local a = vec3(vertices[tri[1]])
		local b = vec3(vertices[tri[2]])
		local c = vec3(vertices[tri[3]])
		pos = pos + a + b + c
	end
	pos = pos / #list / 3
	
	--get normal
	local normal = normals[depth % 3 + 1]
	
	--split
	local left = { }
	local right = { }
	for d,s in ipairs(list) do
		local tri = s[13]
		local a = normal:dot(vertices[tri[1]] - pos) > 0
		local b = normal:dot(vertices[tri[2]] - pos) > 0
		local c = normal:dot(vertices[tri[3]] - pos) > 0
		
		if a == b and b == c and c == a then
			if a then
				--left side
				table.insert(left, s)
			else
				--right side
				table.insert(right, s)
			end
		else
			--both side
			table.insert(left, s)
			table.insert(right, s)
		end
	end
	
	--failed to split, leaf node
	if #left >= #list - threshold or #right >= #list - threshold then
		return list
	end
	
	--new node
	local node = { }
	node.pos = pos
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
	local t = - oz / dz
	if t < 0 or t > maxT then
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
	
	if v >= 0 and u+v <= 1 then
		maxT = t
		maxU = u
		maxV = v
		maxF = m[13]
	end
end

--performs a boolean raytrace on given origin and direction vector
local function raytraceTree(origin, direction, node)
	if node.pos then
		--on which side is the line
		local a = node.normal:dot(vec3(0, 0, 0) - node.pos) > 0
		local b = node.normal:dot(origin, direction - node.pos) > 0
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
		for d,s in ipairs(node) do
			triangleCheck(origin, direction, s)
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

--start of actual physics lib
local raytrace = { }

function raytrace:getNormal(object, maxU, maxV, maxF)
	if object.normals then
		local a = vec3(object.normals[maxF[1]])
		local b = vec3(object.normals[maxF[2]])
		local c = vec3(object.normals[maxF[3]])
		return a * maxU + b * maxV + c * (1.0 - maxU - maxV)
	else
		local a = object.vertices[maxF[1]]
		local b = object.vertices[maxF[2]]
		local c = object.vertices[maxF[3]]
		return (b - a):cross(c - a)
	end
end

function raytrace:getResult()
	return maxT, maxU, maxV, maxF
end

local nearestObject
function raytrace:getObject()
	return nearestObject
end

local function getInvertedTransform(object)
	if not object.inverseTransform then
		object.inverseTransform = object.transform:invert()
	end
	return object.inverseTransform
end

local function transform(origin, direction, object)
	if object.transform then
		local m = getInvertedTransform(object)
		
		return m * origin, vec3({
			m[1] * direction[1] + m[2] * direction[2] + m[3] * direction[3],
			m[5] * direction[1] + m[6] * direction[2] + m[7] * direction[3],
			m[9] * direction[1] + m[10] * direction[2] + m[11] * direction[3],
		})
	else
		return origin, direction
	end
end

function raytrace:raytrace(object, origin, direction, filterTags, inner)
	--clear
	if not inner then
		maxT, maxU, maxV, maxF, nearestObject = 1, false, false, false, false
	end
	
	--object transform
	local localOrigin, localDirection = transform(origin, direction, object)
	
	if object.class == "object" then
		--for all meshes
		for _,s in pairs(object.meshes) do
			if s.vertices then
				self:raytrace(s, localOrigin, localDirection, filterTags, true)
			end
		end
		
		--for all objects
		for _,s in pairs(object.objects) do
			self:raytrace(s, localOrigin, localDirection, filterTags, true)
		end
	elseif object.class == "mesh" then
		if filterTags and not object.tags.raytrace then
			return false
		end
		
		--boundingbox check
		local center = object.boundingBox.center
		local nearest = nearestPointToLine(localOrigin, localOrigin + localDirection, center)
		if (nearest - center):lengthSquared() > object.boundingBox.size^2 then
			return false
		end
		
		--build acceleration structures
		if not object.raytraceTree then
			assert(object.faces, "face buffer required")
			assert(object.vertices, "vertex buffer required")
			object.raytraceTree = buildTree(object.vertices, buildMatrices(object), 1)
		end
		
		--raytrace
		local old = maxT
		raytraceTree(localOrigin, localDirection, object.raytraceTree)
		if old ~= maxT then
			nearestObject = object
		end
	else
		error("object or mesh expected")
	end
	
	--return final position and normal
	if not inner and maxU then
		return origin + maxT * direction
	else
		return false
	end
end

return raytrace