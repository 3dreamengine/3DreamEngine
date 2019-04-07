--[[
#part of the 3DreamEngine by Luke100000
#see init.lua for license and documentation
loader.lua - loads .obj files, loads vertex lists
--]]

local lib = _3DreamEngine

function lib.loadTexture(self, name, path)
	for _,path in ipairs({
		self.objectDir .. name,
		self.objectDir .. path .. "/" .. name,
		path .. "/" .. name,
		name,
		self.root .. "/missing.png"
	}) do
		if love.filesystem.getInfo(path) then
			local t
			local mipMap = path:sub(1, #path-4) .. "_1" .. path:sub(#path-3)
			if love.filesystem.getInfo(mipMap) then
				local maps = {path}
				for i = 1, 16 do
					local mipMap = path:sub(1, #path-4) .. "_" .. i .. path:sub(#path-3)
					if love.filesystem.getInfo(mipMap) then
						maps[#maps+1] = mipMap
					else
						break
					end
				end
				t = love.graphics.newImage(maps, {mipmaps = maps})
				t:setMipmapFilter("nearest")
				t:setFilter("nearest")
			else
				t = love.graphics.newImage(path, {mipmaps = true})
			end
			t:setWrap("repeat")
			return t
		end
	end
end

--[[
name            path to file, starting from root or the set object directory
splitMaterials  to draw several textured (!) materials on one object, it has to be split up first. Keep false for untextured models!
				objects will be renamed to objectName_materialName
rasterMargin	several (untextured) models in one file, where the first one starts at 0|0|0, is sized 1|1|1 and gets the object obj.objects[1][1][1]
				not compatible with splitMaterials! Therefore only one textured material per sub-model (but infinite color-only-materials)
--]]
function lib.loadObject(self, name, splitMaterials, rasterMargin, forceTextured, noMesh)
	if rasterMargin == true then rasterMargin = 2 end
	
	local n = self:split(name, "/")
	local path = #n > 1 and table.concat(n, "/", 1, #n-1) or ""
	
	local obj = {
		materials = {None = {color = {1.0, 1.0, 1.0, 1.0}, specular = 0.5, name = "None"}},
		objects = {
			default = {		
				--store final vertices (vertex, normal and texCoord index)
				final = { },
				
				--store final faces, 3 final indices
				faces = { },
			}
		},
		raster = rasterMargin and true,
	}
	
	obj.objects.default.material = obj.materials.None
	
	--store vertices, normals and texture coordinates
	local vertices = { }
	local normals = { }
	local texVertices = { }
	
	--materials
	if love.filesystem.getInfo(self.objectDir .. name .. ".mtl") or love.filesystem.getInfo(name .. ".mtl") then
		local material = obj.materials.None
		for l in (love.filesystem.getInfo(self.objectDir .. name .. ".mtl") and love.filesystem.lines(self.objectDir .. name .. ".mtl") or love.filesystem.lines(name .. ".mtl")) do
			local v = self:split(l, " ")
			if v[1] == "newmtl" then
				obj.materials[l:sub(8)] = {
					color = {1.0, 1.0, 1.0, 1.0},
					specular = 0.5,
					name = l:sub(8),
				}
				material = obj.materials[l:sub(8)]
			elseif v[1] == "Ks" then
				material.specular = tonumber(v[2])
			elseif v[1] == "Kd" then
				material.color[1] = tonumber(v[2])
				material.color[2] = tonumber(v[3])
				material.color[3] = tonumber(v[4])
			elseif v[1] == "d" then
				material.color[4] = tonumber(v[2])
			elseif v[1] == "map_Kd" then
				material.tex_diffuse = self:loadTexture(l:sub(8), path)
			elseif v[1] == "map_Ks" then
				material.tex_spec = self:loadTexture(l:sub(8), path)
			elseif v[1] == "map_Kn" then
				material.tex_normal = self:loadTexture(l:sub(8), path)
			end
		end
	end
	
	--properties
	if love.filesystem.getInfo(self.objectDir .. name .. ".3de") or love.filesystem.getInfo(name .. ".3de") then
		local mat
		for l in (love.filesystem.getInfo(self.objectDir .. name .. ".3de") and love.filesystem.lines(self.objectDir .. name .. ".3de") or love.filesystem.lines(name .. ".3de")) do
			if l:sub(1, 1) ~= "#" then
				local v = self:split(l, " ")
				if v[1] == "mat" then
					mat = obj.materials[l:sub(5)]
					assert(mat, name .. ".3de, no material named " .. l:sub(5))
				elseif v[1] == "new" then
					if v[2] == "particleSystem" then
						mat.particleSystems = mat.particleSystems or { }
						mat.particleSystems[#mat.particleSystems+1] = {objects = { }, randomSize = {0.75, 1.25}, randomRotation = true, normal = 1.0}
					end
				elseif v[1] == "add" then
					local o = self:loadObject(path .. "/" .. v[2], false, false, false, true)
					for d,s in pairs(o.objects) do
						table.insert(mat.particleSystems[#mat.particleSystems].objects, {object = s, amount = tonumber(v[3]) or 10})
					end
				elseif v[1] == "shader" then
					mat.particleSystems[#mat.particleSystems].shader = v[2]
				elseif v[1] == "shaderInfo" then
					mat.particleSystems[#mat.particleSystems].shaderInfo = v[2]
				elseif v[1] == "randomSize" then
					mat.particleSystems[#mat.particleSystems].randomSize = {tonumber(v[2]), tonumber(v[3])}
				elseif v[1] == "randomRotation" then
					mat.particleSystems[#mat.particleSystems].randomRotation = v[2] == "true"
				elseif v[1] == "randomDistance" then
					mat.particleSystems[#mat.particleSystems].randomDistance = tonumber(v[2]) or 0.0
				elseif v[1] == "normal" then
					mat.particleSystems[#mat.particleSystems].normal = tonumber(v[2])
				end
			end
		end
	end
	
	--load object
	local material = obj.materials.None
	local blocked = false
	local o = obj.objects.default
	for l in (love.filesystem.getInfo(self.objectDir .. name .. ".obj") and love.filesystem.lines(self.objectDir .. name .. ".obj") or love.filesystem.lines(name .. ".obj")) do
		local v = self:split(l, " ")
		if not blocked then
			if v[1] == "v" then
				vertices[#vertices+1] = {tonumber(v[2]), tonumber(v[3]), -tonumber(v[4])}
			elseif v[1] == "vn" then
				normals[#normals+1] = {tonumber(v[2]), tonumber(v[3]), -tonumber(v[4])}
			elseif v[1] == "vt" then
				texVertices[#texVertices+1] = {tonumber(v[2]), 1-tonumber(v[3])}
			elseif v[1] == "usemtl" then
				material = obj.materials[l:sub(8)] or obj.materials.None
				if splitMaterials and not rasterMargin then
					local name = o.name .. "_" .. l:sub(8)
					obj.objects[name] = obj.objects[name] or {
						faces = { },
						final = { },
						name = o.name,
						material = material,
					}
					o = obj.objects[name]
				end
			elseif v[1] == "f" then
				if rasterMargin then
					--split object, where 0|0|0 is the left-front-lower corner of the first object and every splitMargin is a new object with size 1.
					--So each object must be within -margin to splitMargin-margin, a perfect cube will be 0|0|0 to 1|1|1
					local objSize = 1
					local margin = (rasterMargin-objSize)/2
					local v2 = self:split(v[2], "/")
					local x, y, z = vertices[tonumber(v2[1])][1], vertices[tonumber(v2[1])][2], vertices[tonumber(v2[1])][3]
					local tx, ty, tz = math.floor((x+margin)/rasterMargin)+1, math.floor((z+margin)/rasterMargin)+1, math.floor((-y-margin)/rasterMargin)+2
					if not obj.objects[tx] then obj.objects[tx] = { } end
					if not obj.objects[tx][ty] then obj.objects[tx][ty] = { } end
					if not obj.objects[tx][ty][tz] then obj.objects[tx][ty][tz] = {faces = { }, final = { }, material = material} end
					o = obj.objects[tx][ty][tz]
					o.tx = math.floor((x+margin)/rasterMargin)*rasterMargin + objSize/2
					o.ty = math.floor((y+margin)/rasterMargin)*rasterMargin + objSize/2
					o.tz = math.floor((z+margin)/rasterMargin)*rasterMargin + objSize/2
					--print(tx, ty, tz, "|" .. x, y, z, "|" .. x - o.tx, y - o.ty, z - o.tz)
				end
				
				--link material to object, used as draw order identifier
				o.material = material
				
				--combine vertex and data into one
				for i = 1, #v-1 do
					local v2 = self:split(v[i+1]:gsub("//", "/0/"), "/")
					o.final[#o.final+1] = {vertices[tonumber(v2[1])], texVertices[tonumber(v2[2])] or {0, 0}, normals[tonumber(v2[3])], material}
				end
				
				if #v-1 == 3 then
					--tris
					o.faces[#o.faces+1] = {#o.final-0, #o.final-1, #o.final-2}
				elseif #v-1 == 4 then
					--quad
					o.faces[#o.faces+1] = {#o.final-1, #o.final-2, #o.final-3}
					o.faces[#o.faces+1] = {#o.final-0, #o.final-1, #o.final-3}
				else
					error("only tris and quads supported (got " .. (#v-1) .. " vertices)")
				end
			elseif v[1] == "o" then
				local name = l:sub(3) .. (splitMaterials and ("_" .. material.name) or "")
				obj.objects[name] = obj.objects[name] or {
					faces = { },
					final = { },
					name = l:sub(3),
					material = material,
				}
				o = obj.objects[name]
			end
		end
		
		--skip objects named as frame when splitMargin is enabled (frames are used as helper objects)
		if v[1] == "o" and splitMargin then
			if l:find("frame") then
				blocked = true
			else
				blocked = false
			end
		end
	end
	
	--remove empty objects
	for d,s in pairs(obj.objects) do
		if s.final and #s.final == 0 then
			obj.objects[d] = nil
		end
	end
	
	--add particle system objects
	for d,s in pairs(obj.materials) do
		if s.particleSystems then
			for i,v in ipairs(s.particleSystems) do
				obj.objects[s.name .. "_particleSystem_" .. i] = {
					faces = { },
					final = { },
					name = s.name .. "_particleSystem_" .. i,
					particleSystem = true,
					noBackFaceCulling = true,
					material = v.objects[1].object.material or obj.materials.None,
					shader = v.shader,
				}
				
				local po = obj.objects[s.name .. "_particleSystem_" .. i]
				
				for _,o in ipairs(v.objects) do
					local amount = o.amount / #v.objects
					for _,ob in pairs(obj.objects) do
						if not ob.particleSystem then
							for _,f in ipairs(ob.faces) do
								if ob.final[f[1]][4] == s and (amount >= 1 or math.random() < amount) then
									local v1 = ob.final[f[1]][1]
									local v2 = ob.final[f[2]][1]
									local v3 = ob.final[f[3]][1]
									
									--normal vector
									local va = {v1[1] - v2[1], v1[2] - v2[2], v1[3] - v2[3]}
									local vb = {v1[1] - v3[1], v1[2] - v3[2], v1[3] - v3[3]}
									local n = {
										va[2]*vb[3] - va[3]*vb[2],
										va[3]*vb[1] - va[1]*vb[3],
										va[1]*vb[2] - va[2]*vb[1],
									}
									local ln = math.sqrt(n[1]^2+n[2]^2+n[3]^2)
									
									--some particles like grass points towards the sky
									n[1] = n[1] / ln * v.normal
									n[2] = n[2] / ln * v.normal + (1-v.normal)
									n[3] = n[3] / ln * v.normal
									
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
									rotZ = matrix{
										{c, s, 0},
										{-s, c, 0},
										{0, 0, 1},
									}
									
									local c = math.cos(rotX)
									local s = math.sin(rotX)
									rotX = matrix{
										{1, 0, 0},
										{0, c, -s},
										{0, s, c},
									}
									
									--add object to particle system object
									for i = 1, math.floor(area*math.max(1, amount)+math.random()) do
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
										local rotY = v.randomRotation and math.random()*math.pi*2 or 0
										
										local c = math.cos(rotY)
										local s = math.sin(rotY)
										rotY = matrix{
											{c, 0, -s},
											{0, 1, 0},
											{s, 0, c},
										}
										
										local sc = math.random() * (v.randomSize[2] - v.randomSize[1]) + v.randomSize[1]
										local scale = matrix{
											{sc, 0, 0},
											{0, sc, 0},
											{0, 0, sc},
										}
										
										local res = rotX * rotY * rotZ * scale
										
										if v.randomDistance then
											local vn = res * (matrix{{0, 1, 0}}^"T")
											local l = math.sqrt(vn[1][1]^2 + vn[2][1]^2 + vn[3][1]^2)
											x = x + vn[1][1] * v.randomDistance * math.random() / l
											y = y + vn[2][1] * v.randomDistance * math.random() / l
											z = z + vn[3][1] * v.randomDistance * math.random() / l
										end
										
										--insert finals and faces
										local lastIndex = #po.final
										for d,s in ipairs(o.object.final) do
											local vp = res * (matrix{s[1]}^"T")
											vp = {vp[1][1], vp[2][1], vp[3][1]}
											
											local vn = res * (matrix{s[3]}^"T")
											vn = {vn[1][1], vn[2][1], vn[3][1]}
											
											local extra
											if v.shader == "wind" then
												if v.shaderInfo == "grass" then
													extra = math.min(1.0, math.max(0.0, s[1][2]))
												else
													extra = tonumber(v.shaderInfo) or 0.15
												end
											end
											
											po.final[#po.final+1] = {{vp[1]+x, vp[2]+y, vp[3]+z, extra}, s[2], {vn[1], vn[2], vn[3]}, s[4], s[5]}
										end
										for d,s in ipairs(o.object.faces) do
											po.faces[#po.faces+1] = {s[1]+lastIndex, s[2]+lastIndex, s[3]+lastIndex}
										end
									end
								end
							end
						end
					end
				end
				
				print(s.name .. ": " .. #po.faces .. " particle-faces") io.flush()
			end
		end
	end
	
	--fill mesh(es)
	if not noMesh then
		if rasterMargin then
			for x, dx in pairs(obj.objects) do
				for y, dy in pairs(dx) do
					for z, dz in pairs(dy) do
						--move sub objects
						for i,v in ipairs(dz.final) do
							if not v[1][4] then
								v[1][1] = v[1][1] - (dz.tx or 0)
								v[1][2] = v[1][2] - (dz.ty or 0)
								v[1][3] = v[1][3] - (dz.tz or 0)
								v[1][4] = true
							end
						end
						for i,v in ipairs(dz.final) do
							v[1][4] = nil
						end
						self:createMesh(dz, obj)
					end
				end
			end
		else
			for d,s in pairs(obj.objects) do
				self:createMesh(s, obj, nil, forceTextured)
			end
		end
	end
	
	return obj
end

--takes an final and face object and a base object and generates the mesh and vertexMap
function lib.createMesh(self, o, obj, faceMap, forceTextured)
	if not o.material then
		o.material = {color = {1.0, 1.0, 1.0, 1.0}, specular = 0.5, name = "None"}
	end
	local atypes
	if o.material.tex_diffuse or forceTextured then
		atypes = {
		  {"VertexPosition", "float", 4},	-- x, y, z
		  {"VertexTexCoord", "float", 2},	-- UV
		  {"VertexColor", "byte", 4},		-- normal, specular
		}
	else
		atypes = {
		  {"VertexPosition", "float", 4},	-- x, y, z
		  {"VertexTexCoord", "float", 4},	-- normal, specular
		  {"VertexColor", "byte", 4},		-- color
		}
	end
	
	--compress finals (not all used)
	local vertexMap = { }
	local final = { }
	local finalIDs = { }
	if faceMap then
		for d,f in ipairs(faceMap) do
			finalIDs = { }
			for i = 1, 3 do
				if not finalIDs[f[1][i]] then
					local fc = f[2][f[1][i]]
					local x, z = self:rotatePoint(fc[1][1], fc[1][3], -f[6])
					local nx, nz = self:rotatePoint(fc[3][1], fc[3][3], -f[6])
					final[#final+1] = {{x + f[3], fc[1][2] + f[4], z + f[5]}, fc[2], {nx, fc[3][2], nz}, fc[4]}
					finalIDs[f[1][i]] = #final
				end
				vertexMap[#vertexMap+1] = finalIDs[f[1][i]]
			end
		end
	else
		for d,f in ipairs(o.faces) do
			for i = 1, 3 do
				if not finalIDs[f[i]] then
					final[#final+1] = o.final[f[i]]
					finalIDs[f[i]] = #final
				end
				vertexMap[#vertexMap+1] = finalIDs[f[i]]
			end
		end
	end
	
	--create mesh
	o.mesh = love.graphics.newMesh(atypes, #final, "triangles", "static")
	for d,s in ipairs(final) do
		vertexMap[#vertexMap+1] = s[i]
		local p = s[1]
		local t = s[2]
		local n = s[3]
		local m = s[4]
		local c = s[5] or m.color
		if o.material.tex_diffuse or forceTextured then
			o.mesh:setVertex(d,
				p[1], p[2], p[3], p[4] or 1.0,
				t[1], t[2],
				n[1]*0.5+0.5, n[2]*0.5+0.5, n[3]*0.5+0.5,
				m.specular
			)
		else
			o.mesh:setVertex(d,
				p[1], p[2], p[3], p[4] or 1.0,
				n[1]*0.5+0.5, n[2]*0.5+0.5, n[3]*0.5+0.5,
				m.specular,
				c[1], c[2], c[3], c[4]
			)
		end
	end
	
	--set diffuse texture
	if o.material.tex_diffuse then
		o.mesh:setTexture(o.material.tex_diffuse)
	end
	
	--vertex map
	o.mesh:setVertexMap(vertexMap)
end

--creates a triangle mesh based on position/color/specular (x, y, z, [r, g, b, spec]) points
--[[
#outdated, use with caution
function lib.loadCustomObject(self, vertices)
	local o = { }
	
	o.vertices = vertices
	for i = 1, #vertices/3 do
		local v1 = vertices[(i-1)*3 + 1]
		local v2 = vertices[(i-1)*3 + 2]
		local v3 = vertices[(i-1)*3 + 3]
		
		local a = {v1[1] - v2[1], v1[2] - v2[2], v1[3] - v2[3]}
		local b = {v1[1] - v3[1], v1[2] - v3[2], v1[3] - v3[3]}
		
		local n = {
			(a[2]*b[3] - a[3]*b[2]),
			(a[3]*b[1] - a[1]*b[3]),
			(a[1]*b[2] - a[2]*b[1]),
		}
		
		local l = math.sqrt(n[1]^2+n[2]^2+n[3]^2)
		n[1] = n[1] / l
		n[2] = n[2] / l
		n[3] = n[3] / l
		
		v1[8] = n[1]
		v1[9] = n[2]
		v1[10] = n[3]
		
		v2[8] = n[1]
		v2[9] = n[2]
		v2[10] = n[3]
		
		v3[8] = n[1]
		v3[9] = n[2]
		v3[10] = n[3]
	end
	
	local atypes = {
		{"VertexPosition", "float", 3},	-- x, y, z
		{"VertexTexCoord", "float", 4},	-- normal, specular
		{"VertexColor", "float", 4},	-- color
	}
	
	--fill mesh
	local lastMaterial
	o.mesh = love.graphics.newMesh(atypes, #vertices, "triangles", "static")
	for d,s in ipairs(vertices) do
		o.mesh:setVertex(d,
			s[1], s[2], s[3],
			s[8]*0.5+0.5, s[9]*0.5+0.5, s[10]*0.5+0.5,
			s[7] or 0.5,
			s[4], s[5], s[6], 1.0
		)
	end
	
	return {objects.default = o}
end
--]]