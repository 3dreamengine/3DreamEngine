--[[
#part of the 3DreamEngine by Luke100000
particlesystem.lua - generates particle meshes based on .mat instructions
--]]

local lib = _3DreamEngine

--add particle system objects
--for every sub object (which is not a particle mesh) with a material with an attached particle systems create a new object (the particles)
--assigning several materials to one object without the split arg therefore wont work properly
function lib.addParticlesystems(self, obj)
	for oName, o in pairs(obj.objects) do
		if o.material.particleSystems and not o.particleSystem then
			
			--load objects of particle system
			if not o.material.particleSystems.loaded then
				o.material.particleSystems.loaded = true
				for psID, ps in ipairs(o.material.particleSystems) do
					ps.objects_new = { }
					ps.randomSize = ps.randomSize or {0.75, 1.25}
					ps.normal = ps.normal or 1.0
					
					for i,v in pairs(ps.objects) do
						local o = self:loadObject(i, {noCleanup = true, noMesh = true})
						for d,s in pairs(o.objects) do
							table.insert(ps.objects_new, {object = s, material = s.material, amount = v})
							s.material.shader = ps.shader
						end
					end
					
					ps.objects, ps.objects_new = ps.objects_new, ps.objects
				end
			end
			
			for particleSystemID, particleSystem in ipairs(o.material.particleSystems) do
				local t = love.timer.getTime()
				
				--create the particle mesh
				local pname = o.name .. "_particleSystem_" .. o.material.name .. "_" .. particleSystemID
				obj.objects[pname] = dream:newSubObject(pname, obj, particleSystem.objects[1].object.material or obj.materials.None)
				obj.objects[pname].particleSystem = true
				local po = obj.objects[pname]
				
				--place particles
				for _,particle in ipairs(particleSystem.objects) do
					local amount = particle.amount / #particleSystem.objects
					local particleVertexPerformanceImpact = (128 + #particle.object.final) / 128
					
					for _,f in ipairs(o.faces) do
						if o.final[f[1]][8] == o.material and (amount >= 1 or math.random() < amount) then
							local v1 = o.final[f[1]]
							local v2 = o.final[f[2]]
							local v3 = o.final[f[3]]
							
							--normal vector
							local va = {v1[1] - v2[1], v1[2] - v2[2], v1[3] - v2[3]}
							local vb = {v1[1] - v3[1], v1[2] - v3[2], v1[3] - v3[3]}
							local n = {
								o.final[f[1]][5] + o.final[f[2]][5] + o.final[f[3]][5],
								o.final[f[1]][6] + o.final[f[2]][6] + o.final[f[3]][6],
								o.final[f[1]][7] + o.final[f[2]][7] + o.final[f[3]][7]
							}
							
							--some particles like grass points towards the sky
							n[1] = n[1] * particleSystem.normal
							n[2] = n[2] * particleSystem.normal + (1-particleSystem.normal)
							n[3] = n[3] * particleSystem.normal
							
							--area of the plane
							local a = math.sqrt((v1[1]-v2[1])^2 + (v1[2]-v2[2])^2 + (v1[3]-v2[3])^2)
							local b = math.sqrt((v2[1]-v3[1])^2 + (v2[2]-v3[2])^2 + (v2[3]-v3[3])^2)
							local c = math.sqrt((v3[1]-v1[1])^2 + (v3[2]-v1[2])^2 + (v3[3]-v1[3])^2)
							local s = (a+b+c)/2
							local area = math.sqrt(s*(s-a)*(s-b)*(s-c))
							
							local rotZ = math.asin(n[1] / math.sqrt(n[1]^2+n[2]^2))
							local rotX = math.asin(n[3] / math.sqrt(n[2]^2+n[3]^2))
							
							local c = math.cos(rotZ)
							local s = math.sin(rotZ)
							rotZ = mat3(
								c, s, 0,
								-s, c, 0,
								0, 0, 1
							)
							
							local c = math.cos(rotX)
							local s = math.sin(rotX)
							rotX = mat3(
								1, 0, 0,
								0, c, -s,
								0, s, c
							)
							
							--add object to particle system object
							local am = math.floor(area*math.max(1, amount)+math.random())
							
							for i = 1, am do
								--location on the plane
								local f1 = math.random()
								local f2 = math.random()
								local f3 = math.random()
								local f = f1+f2+f3
								f1 = f1 / f
								f2 = f2 / f
								f3 = f3 / f
								
								local x = v1[1]*f1 + v2[1]*f2 + v3[1]*f3
								local y = v1[2]*f1 + v2[2]*f2 + v3[2]*f3
								local z = v1[3]*f1 + v2[3]*f2 + v3[3]*f3
								
								--rotation matrix
								local rotY = particleSystem.randomRotation and math.random()*math.pi*2 or 0
								
								local c = math.cos(rotY)
								local s = math.sin(rotY)
								rotY = mat3(
									c, 0, -s,
									0, 1, 0,
									s, 0, c
								)
								
								local sc = math.random() * (particleSystem.randomSize[2] - particleSystem.randomSize[1]) + particleSystem.randomSize[1]
								local scale = mat3(
									sc, 0, 0,
									0, sc, 0,
									0, 0, sc
								)
								
								local res = rotX * rotY * rotZ * scale
								
								if particleSystem.randomDistance then
									local vn = res * vec3(0, 1, 0)
									local l = vn:length()
									x = x + vn[1] * particleSystem.randomDistance * math.random() / l
									y = y + vn[2] * particleSystem.randomDistance * math.random() / l
									z = z + vn[3] * particleSystem.randomDistance * math.random() / l
								end
								
								--insert finals and faces
								local lastIndex = #po.final
								for d,s in ipairs(particle.object.final) do
									local vp = res * vec3(s[1], s[2], s[3])
									local vn = res * vec3(s[5], s[6], s[7])
									
									local extra = 1.0
									if particleSystem.shader == "wind" then
										if particleSystem.shaderValue == "grass" then
											extra = math.min(1.0, math.max(0.0, s[2] * 0.25)) * (particleSystem.shaderValueGrass or 1.0)
										else
											extra = tonumber(particleSystem.shaderValue) or 0.15
										end
									end
									
									po.final[#po.final+1] = {
										vp[1]+x, vp[2]+y, vp[3]+z, --position
										extra,                     --optional extra value
										vn[1], vn[2], vn[3],       --normal
										s[8],                      --material
										s[9], s[10],               --UV
									}
								end
								for d,s in ipairs(particle.object.faces) do
									po.faces[#po.faces+1] = {s[1]+lastIndex, s[2]+lastIndex, s[3]+lastIndex}
								end
							end
						end
					end
				end
				
				print(o.material.name .. ": " .. #po.faces .. " particle-faces") io.flush()
			end
		end
	end
end