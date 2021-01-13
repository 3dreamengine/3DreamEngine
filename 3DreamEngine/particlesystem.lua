--[[
#part of the 3DreamEngine by Luke100000
particlesystem.lua - generates particle meshes based on .mat instructions
--]]

local lib = _3DreamEngine

--load a list of particle objects and prepare them
local function loadParticles(self, particleSystems)
	for _, ps in ipairs(particleSystems) do
		if ps.randomSize then
			print("warning: depricated particlesystem.randomSize found! Particle systems have changed.")
		end
		
		--default values
		ps.size = ps.size or {0.75, 1.25}
		ps.rotation = ps.rotation or 0.0
		ps.tilt = ps.tilt or 1.0
		
		ps.input = ps.input or { }
		
		ps.loadedObjects = { }
		for i,v in pairs(ps.objects) do
			local o = self:loadObject(i, {cleanup = false, noMesh = true, noParticleSystem = true})
			
			--extract subObjects
			for d,s in pairs(o.objects) do
				s.particleDensity = v
				table.insert(ps.loadedObjects, s)
			end
		end
	end
end

--fetches an input from the color buffer
--TODO support for additional vertex/color/UV maps
local ones = {
	get = function()
		return 1
	end,
	getMax = function()
		return 1
	end,
}
local imageDataCache = { }
local function getInput(input, o, f)
	if input then
		if input.source == "image" then
			local dat = imageDataCache[input.path]
			local width, height = dat:getDimensions()
			local b = o[input.buffer or "texCoords"]
			assert(b, "required buffer " .. input.buffer .. " not present")
			local uv1 = b[f[1]]
			local uv2 = b[f[2]]
			local uv3 = b[f[3]]
			
			return {
				get = function(self, u, v, w)
					local x = math.floor((uv1[1] * u + uv2[1] * v + uv3[1] * w) * width)
					local y = math.floor((uv1[2] * u + uv2[2] * v + uv3[2] * w) * height)
					local v = ({dat:getPixel(math.clamp(x, 0, width-1), math.clamp(y, 0, height-1))})[input.channel]
					return (input.invert and (1.0 - v) or v) * (input.mul or 1.0) + (input.add or 0.0)
				end,
				getMax = function(self)
					return 0.999
				end,
			}
		else
			local dat = input.invert and {
				(1 - o.colors[f[1]][input.channel]) * (input.mul or 1.0) + (input.add or 0.0),
				(1 - o.colors[f[2]][input.channel]) * (input.mul or 1.0) + (input.add or 0.0),
				(1 - o.colors[f[3]][input.channel]) * (input.mul or 1.0) + (input.add or 0.0)
			} or #o.colors > 0 and {
				o.colors[f[1]][input.channel] * (input.mul or 1.0) + (input.add or 0.0),
				o.colors[f[2]][input.channel] * (input.mul or 1.0) + (input.add or 0.0),
				o.colors[f[3]][input.channel] * (input.mul or 1.0) + (input.add or 0.0)
			} or {0, 0, 0}
			
			return {
				get = function(self, u, v, w)
					return dat[1] * u + dat[2] * v + dat[3] * w
				end,
				getMax = function(self)
					return math.max(dat[1], dat[2], dat[3])
				end,
			}
		end
	else
		return ones
	end
end

--add particle system objects
--for every sub object (which is not a particle mesh itself) with a material with an attached particle systems create a new object (the particles)
--assigning several materials to one object without the split arg therefore wont work properly
function lib:addParticlesystems(obj)
	for oName, o in pairs(obj.objects) do
		local particleSystems = o.material.particleSystems
		if particleSystems and not o.tags.particle then
			--load objects of particle system into respective material
			if not particleSystems.loaded then
				particleSystems.loaded = true
				loadParticles(self, particleSystems)
			end
			
			--remove emitter
			if particleSystems.removeEmitter then
				obj.objects[oName] = nil
			end
			
			--some shader rely on the vertical height, assuming the emitters transform is final it uses it as the global orientation
			local orientation = vec3(0, 1, 0)
			if o.transform then
				orientation = o.transform * orientation
			end
			
			--load required imageData
			for psID, ps in ipairs(particleSystems) do
				for _,input in pairs(ps.input) do
					if input.source == "image" then
						if not imageDataCache[input.path] then
							assert(self.images[input.path], "image " .. tostring(input.path) .. " does not exist!")
							print("warning: particlesystem #" .. psID .. " of material " .. o.material.name .. " uses an (slow) image source. Use 3DO export for the final build")
							imageDataCache[input.path] = love.image.newImageData(self.images[input.path])
						end
					end
				end
			end
			
			--place them
			for psID, ps in ipairs(particleSystems) do
				assert(#ps.loadedObjects > 0, "particle systems imported objects are empty")
				
				--list particles to spawn
				local transforms = { }
				for _,particle in ipairs(ps.loadedObjects) do
					local mat = particle.material
					if not transforms[mat] then
						transforms[mat] = {
							min = vec3(math.huge, math.huge, math.huge),
							max = vec3(-math.huge, -math.huge, -math.huge),
							vertices = 0
						}
					end
					local t = transforms[mat]
					
					local top = particle.transform and (particle.transform:subm():invert() * vec3(0, 1, 0)) or vec3(0, 1, 0)
					
					--per face
					local particleDensity = particle.particleDensity / #ps.loadedObjects
					for _,f in ipairs(o.faces) do
						local v1 = vec3(o.vertices[f[1]])
						local v2 = vec3(o.vertices[f[2]])
						local v3 = vec3(o.vertices[f[3]])
						
						--area of the plane
						local a = (v1-v2):length()
						local b = (v2-v3):length()
						local c = (v3-v1):length()
						local s = (a+b+c)/2
						local area = math.sqrt(s*(s-a)*(s-b)*(s-c))
						
						--specific input for density
						local density, maxDensity = getInput(ps.input.density, o, f)
						local maxDensity = density:getMax()
						local size = getInput(ps.input.size, o, f)
						
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
								local normal = vec3(o.normals[f[1]]) * u + vec3(o.normals[f[1]]) * v + vec3(o.normals[f[1]]) * w
								
								--randomize normal
								if ps.rotation > 0 then
									normal = vec3(math.random()-0.5, math.random()-0.5, math.random()-0.5) * ps.rotation + normal * (1 - ps.rotation)
								end
								normal = normal:normalize()
								
								--scale
								local sc = (math.random() * (ps.size[2] - ps.size[1]) + ps.size[1]) * size:get(u, v, w)
								
								--get transformation matrix to transform from particle to normal
								local vec = top:cross(normal)
								local angle = math.acos(top:dot(normal))
								local dir = (vec:length() == 0 and normal:cross(vec3(1, 2, 3)) or vec):normalize()
								local transform = mat3:getRotate(dir, angle) * sc
								
								--tilt
								if ps.tilt > 0 then
									transform = mat3:getRotate(normal, (math.random() - 0.5) * math.pi * 2) * transform
								end
								
								--insert
								local p = v1 * u + vec3(v2) * v + vec3(v3) * w
								t.min = t.min:min(p)
								t.max = t.max:max(p)
								t.vertices = t.vertices + #particle.vertices
								table.insert(t, {
									pos = p,
									transform = transform,
									particle = particle,
								})
							end
						end
					end
				end
				
				--for each material of the transforms
				local matID = 0
				for mat, transforms in pairs(transforms) do
					local t = 0.0001
					transforms.min = transforms.min - vec3(t, t, t)
					transforms.max = transforms.max + vec3(t, t, t)
					
					--find best splitting layout
					local target = 10000
					local splits = vec3(1, 1, 1)
					local size = transforms.max - transforms.min
					while transforms.vertices / (splits[1] * splits[2] * splits[3]) > target do
						local max = math.max(unpack(size / splits))
						for i = 1, 3 do
							if size[i] / splits[i] == max then
								splits[i] = splits[i] + 1
								break
							end
						end
					end
					
					--create the particle mesh
					local delta = size / splits
					local ID = 0
					matID = matID + 1
					for x = transforms.min.x, transforms.max.x, delta.x do
						for y = transforms.min.y, transforms.max.y, delta.y do
							for z = transforms.min.z, transforms.max.z, delta.z do
								ID = ID + 1
								
								local pname = oName .. "_ps_" .. psID .. "_" .. matID .. "_" .. ID
								local po = dream:newSubObject(o.name, obj, ps.loadedObjects[1].material)
								obj.objects[pname] = po
								po.transform = o.transform
								po.tags.particle = true
								po.LOD_center = true
								po:setLOD(0, 1, true)
								for _, s in ipairs(transforms) do
									local p = s.pos
									if p.x > x and p.x <= x + delta.x and p.y > y and p.y <= y + delta.y and p.z > z and p.z <= z + delta.z then
										local transform = s.transform
										local particle = s.particle
										
										--insert vertices and faces
										local lastIndex = #po.vertices
										for d,s in ipairs(particle.vertices) do
											--transform
											local vp = transform * vec3(s) + p
											local vn = (transform * vec3(particle.normals[d])):normalize()
											
											--calculate extra based on given shader and shaderValue
											local extra = 1.0
											if ps.shader == "wind" then
												if ps.shaderValue == "grass" then
													extra = math.max(0.0, (orientation * s):length() * (ps.shaderValueGrass or 0.25))
												else
													extra = tonumber(ps.shaderValue) or 0.15
												end
											end
											
											--merge data
											local index = #po.vertices+1
											local emission = po.material.emission or 0
											if type(emission) == "table" then
												emission = math.sqrt(emission[1]^2+emission[2]^2+emission[3]^2)
											end
											po.vertices[index] = vp
											po.extras[index] = extra
											po.normals[index] = vn
											po.materials[index] = {po.material.specular, po.material.glossiness, emission}
											po.texCoords[index] = particle.texCoords[d]
											po.colors[index] = po.material.color
										end
										
										for d,s in ipairs(particle.faces) do
											po.faces[#po.faces+1] = {s[1]+lastIndex, s[2]+lastIndex, s[3]+lastIndex}
										end
									end
								end
							end
						end
					end
				end
			end
		end
	end
	imageDataCache = { }
end