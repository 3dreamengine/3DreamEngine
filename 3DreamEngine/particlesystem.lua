--[[
#part of the 3DreamEngine by Luke100000
particlesystem.lua - generates particle meshes based on .mat instructions
--]]

local lib = _3DreamEngine

--load a list of particle objects and prepare them
local function loadParticles(self, particleSystems)
	for _, ps in ipairs(particleSystems) do
		--default values
		ps.size = ps.size or { 0.75, 1.25 }
		ps.rotation = ps.rotation or 0.0
		ps.tilt = ps.tilt ~= false
		
		ps.input = ps.input or { }
		
		ps.loadedObjects = { }
		for i, v in pairs(ps.objects) do
			local o = self:loadObject(i, { cleanup = false, mesh = false, particleSystems = false })
			
			--extract meshes
			for _, mesh in pairs(o.meshes) do
				if mesh.vertices then
					mesh.particleDensity = v
					table.insert(ps.loadedObjects, mesh)
				end
			end
		end
	end
end

--fetches an input from the color buffer
local ones = {
	get = function()
		return 1
	end,
	getMax = function()
		return 1
	end,
}
local function getInput(input, mesh, face)
	if input then
		error()
		local b = mesh[input.buffer or "colors"]
		if not b then
			error("Buffer " .. tostring(input.buffer or "colors") .. " does not exist!")
		end
		local dat = input.invert and {
			(1 - b:getVector(face.x)[input.channel]) * (input.mul or 1.0) + (input.add or 0.0),
			(1 - b:getVector(face.y)[input.channel]) * (input.mul or 1.0) + (input.add or 0.0),
			(1 - b:getVector(face.z)[input.channel]) * (input.mul or 1.0) + (input.add or 0.0)
		} or b:getSize() > 0 and {
			b:getVector(face.x)[input.channel] * (input.mul or 1.0) + (input.add or 0.0),
			b:getVector(face.y)[input.channel] * (input.mul or 1.0) + (input.add or 0.0),
			b:getVector(face.z)[input.channel] * (input.mul or 1.0) + (input.add or 0.0)
		} or { 0, 0, 0 }
		
		return {
			get = function(self, u, v, w)
				return dat[1] * u + dat[2] * v + dat[3] * w
			end,
			getMax = function(self)
				return math.max(dat[1], dat[2], dat[3])
			end,
		}
	else
		return ones
	end
end

--add particle system objects
--for every mesh (which is not a particle mesh itself) with a material with attached particle systems create a new object (the particles)
function lib:addParticleSystems(obj)
	local meshes = { }
	for oName, o in pairs(obj.meshes) do
		local particleSystems = o.material.particleSystems
		if particleSystems and not o.isParticle then
			meshes[oName] = o
		end
	end
	
	for meshName, mesh in pairs(meshes) do
		local particleSystems = mesh.material.particleSystems
		
		--load objects of particle system into respective material
		if not particleSystems.loaded then
			particleSystems.loaded = true
			loadParticles(self, particleSystems)
		end
		
		--remove emitter
		if particleSystems.removeEmitter then
			obj.meshes[meshName] = nil
		end
		
		--place them
		for psID, ps in ipairs(particleSystems) do
			assert(#ps.loadedObjects > 0, "particle systems imported objects are empty")
			
			--list particles to spawn
			for pID, particle in ipairs(ps.loadedObjects) do
				local t = {
					min = vec3(math.huge, math.huge, math.huge),
					max = vec3(-math.huge, -math.huge, -math.huge),
					maxScale = 0,
					particles = { },
				}
				
				--per face
				local particleDensity = particle.particleDensity / #ps.loadedObjects
				for _, face in mesh.faces:ipairs() do
					local v1 = mesh.vertices:getVector(face.x)
					local v2 = mesh.vertices:getVector(face.y)
					local v3 = mesh.vertices:getVector(face.z)
					
					--area of the plane
					local a = (v1 - v2):length()
					local b = (v2 - v3):length()
					local c = (v3 - v1):length()
					local s = (a + b + c) / 2
					local area = math.sqrt(s * (s - a) * (s - b) * (s - c))
					
					--specific input for density
					local density = getInput(ps.input.density, mesh, face)
					local maxDensity = density:getMax()
					local size = getInput(ps.input.size, mesh, face)
					
					--amount of objects
					local am = math.floor(area * maxDensity * particleDensity + math.random())
					
					--add objects
					for i = 1, am do
						local u = math.random()
						local v = math.random()
						
						--flip to match triangle instead of quad
						if v > 1 - u then
							u = 1 - u
							v = 1 - v
						end
						
						local w = (1 - u - v)
						
						--interpolated per vertex density
						if maxDensity == 1.0 or density:get(u, v, w) / maxDensity > math.random() then
							--interpolated normal and position
							local normal = mesh.normals:getVector(face.x) * u + mesh.normals:getVector(face.y) * v + mesh.normals:getVector(face.z) * w
							
							--randomize normal
							if ps.rotation > 0 then
								normal = vec3(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5) * ps.rotation + normal * (1 - ps.rotation)
							end
							normal = normal:normalize()
							
							--scale
							local sc = (math.random() * (ps.size[2] - ps.size[1]) + ps.size[1]) * size:get(u, v, w)
							
							--get transformation matrix to transform from local to tangent space
							local top = vec3(0, 1, 0)
							local vec = top:cross(normal)
							local angle = -math.acos(top:dot(normal))
							local transform = math.abs(angle) < 0.00001 and mat3.getIdentity() or mat3.getRotate(vec, angle) * sc
							
							t.maxScale = math.max(t.maxScale, sc)
							
							--tilt
							if ps.tilt then
								transform = transform * mat3.getRotate(normal, (math.random() - 0.5) * math.pi * 2)
							end
							
							--apply particle transform
							if particle.transform then
								transform = particle.transform:subm():invert() * transform
							end
							
							--insert
							local pos = v1 * u + vec3(v2) * v + vec3(v3) * w
							t.min = t.min:min(pos)
							t.max = t.max:max(pos)
							table.insert(t.particles, {
								pos = pos,
								transform = transform,
							})
						end
					end
				end
				
				--anti divide by zero
				local _min = 0.0001
				t.min = t.min - vec3(_min, _min, _min)
				t.max = t.max + vec3(_min, _min, _min)
				
				--find best splitting layout
				local splits = vec3(1, 1, 1)
				local size = t.max - t.min
				local vertices = particle.vertices:getSize() * #t.particles
				while vertices / (splits[1] * splits[2] * splits[3]) > (ps.maxCellVertexCount or 10000) do
					local max = math.max(table.unpack(size / splits))
					for i = 1, 3 do
						if size[i] / splits[i] == max then
							splits[i] = splits[i] + 1
							break
						end
					end
				end
				
				--create the particle mesh
				local delta = size / splits
				if ps.maxCellSize then
					delta = delta:min(ps.maxCellSize)
				end
				local ID = 0
				for x = t.min.x, t.max.x, delta.x do
					for y = t.min.y, t.max.y, delta.y do
						for z = t.min.z, t.max.z, delta.z do
							--generate instance transforms
							local transforms = { }
							for _, s in ipairs(t.particles) do
								local p = s.pos
								if p.x > x and p.x <= x + delta.x and p.y > y and p.y <= y + delta.y and p.z > z and p.z <= z + delta.z then
									table.insert(transforms, {
										s.transform[1], s.transform[2], s.transform[3],
										s.transform[4], s.transform[5], s.transform[6],
										s.transform[7], s.transform[8], s.transform[9],
										p[1], p[2], p[3]
									})
								end
							end
							
							--create mesh
							if #transforms > 0 then
								ID = ID + 1
								
								--prepare new mesh
								local pname = meshName .. "_ps_" .. psID .. "_" .. pID .. "_" .. ID
								local po = lib:newObject(pname)
								local pm = particle:clone()
								po.meshes[pname] = pm
								obj.objects[pname] = po
								
								po.transform = mesh.transform
								pm.isParticle = true
								
								local sz = particle.boundingBox.size * t.maxScale
								local margin = vec3(sz, sz, sz)
								
								pm:addInstances(transforms)
								
								pm.boundingBox = self:newBoundingBox(vec3(x, y, z) - margin, po.boundingBox.first + delta + margin * 2)
								po:updateBoundingBox()
							end
						end
					end
				end
			end
		end
	end
end