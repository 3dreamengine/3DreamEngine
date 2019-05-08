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
		splitMaterials = splitMaterials,
		rasterMargin = rasterMargin
	}
	
	obj.objects.default.material = obj.materials.None
	
	--load files
	--if two object files are available (.obj and .vox) it might crash, since it loads all
	for _,typ in ipairs({
		"mtl",
		"obj",
		"vox",
		"3de",
		"3db",
	}) do
		if love.filesystem.getInfo(self.objectDir .. name .. "." .. typ) or love.filesystem.getInfo(name .. "." .. typ) then
			self.loader[typ](self, obj, name, path)
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
													extra = math.min(1.0, math.max(0.0, s[1][2] * 0.25))
												else
													extra = tonumber(v.shaderInfo) or 0.15
												end
											end
											
											po.final[#po.final+1] = {
												{vp[1]+x, vp[2]+y, vp[3]+z, extra}, --position and optional extra value
												s[2],                               --UV
												{vn[1], vn[2], vn[3]},              --normal
												s[4],                               --material
												s[5]                                --optional color
											}
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
		  {"VertexNormal", "float", 3},		-- normal
		  {"VertexTangent", "float", 3},	-- normal tangent
		  {"VertexBitangent", "float", 3},	-- normal bitangent
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
	local finals = { }
	local finalsIDs = { }
	if faceMap then
		for d,f in ipairs(faceMap) do
			finalsIDs = { }
			for i = 1, 3 do
				if not finalsIDs[f[1][i]] then
					local fc = f[2][f[1][i]]
					local x, z = self:rotatePoint(fc[1][1], fc[1][3], -f[6])
					local nx, nz = self:rotatePoint(fc[3][1], fc[3][3], -f[6])
					finals[#finals+1] = {{x + f[3], fc[1][2] + f[4], z + f[5]}, fc[2], {nx, fc[3][2], nz}, fc[4]}
					finalsIDs[f[1][i]] = #finals
				end
				vertexMap[#vertexMap+1] = finalsIDs[f[1][i]]
			end
		end
	else
		for d,f in ipairs(o.faces) do
			for i = 1, 3 do
				if not finalsIDs[f[i]] then
					finals[#finals+1] = o.final[f[i]]
					finalsIDs[f[i]] = #finals
				end
				vertexMap[#vertexMap+1] = finalsIDs[f[i]]
			end
		end
	end
	
	--calculate vertex normals and uv normals
	for f = 1, #vertexMap, 3 do
		local P1 = finals[vertexMap[f+0]][1]
		local P2 = finals[vertexMap[f+1]][1]
		local P3 = finals[vertexMap[f+2]][1]
		local N1 = finals[vertexMap[f+0]][2]
		local N2 = finals[vertexMap[f+1]][2]
		local N3 = finals[vertexMap[f+2]][2]
		
		local tangent = { }
		local bitangent = { }
		
		local edge1 = {P2[1] - P1[1], P2[2] - P1[2], P2[3] - P1[3]}
		local edge2 = {P3[1] - P1[1], P3[2] - P1[2], P3[3] - P1[3]}
		local edge1uv = {N2[1] - N1[1], N2[2] - N1[2]}
		local edge2uv = {N3[1] - N1[1], N3[2] - N1[2]}
		
		local cp = edge1uv[2] * edge2uv[1] - edge1uv[1] * edge2uv[2]
		
		if cp ~= 0.0 then
			for i = 1, 3 do
				tangent[i] = (edge1[i] * (-edge2uv[2]) + edge2[i] * edge1uv[2]) / cp
				bitangent[i] = (edge1[i] * (-edge2uv[1]) + edge2[i] * edge1uv[1]) / cp
			end
			
			local l = math.sqrt(tangent[1]^2+tangent[2]^2+tangent[3]^2)
			tangent[1] = tangent[1] / l
			tangent[2] = tangent[2] / l
			tangent[3] = tangent[3] / l
			
			local l = math.sqrt(bitangent[1]^2+bitangent[2]^2+bitangent[3]^2)
			bitangent[1] = bitangent[1] / l
			bitangent[2] = bitangent[2] / l
			bitangent[3] = bitangent[3] / l
			
			for i = 1, 3 do
				if not finals[vertexMap[f+i-1]][6] then
					finals[vertexMap[f+i-1]][6] = {0, 0, 0}
					finals[vertexMap[f+i-1]][7] = {0, 0, 0}
					finals[vertexMap[f+i-1]][8] = {0, 0, 0}
				end
				for c = 1, 3 do
					finals[vertexMap[f+i-1]][6][c] = finals[vertexMap[f+i-1]][6][c] + tangent[c]
					finals[vertexMap[f+i-1]][7][c] = finals[vertexMap[f+i-1]][7][c] + bitangent[c]
				end
			end
		end
	end
	
	--complete smoothing step
	for d,f in ipairs(finals) do
		if f[6] then
			local l = math.sqrt(f[6][1]^2+f[6][2]^2+f[6][3]^2)
			f[6][1] = f[6][1] / l
			f[6][2] = f[6][2] / l
			f[6][3] = f[6][3] / l
			
			local l = math.sqrt(f[7][1]^2+f[7][2]^2+f[7][3]^2)
			f[7][1] = f[7][1] / l
			f[7][2] = f[7][2] / l
			f[7][3] = f[7][3] / l
			
--			f[8][1] = f[6][2]*f[7][3] - f[6][3]*f[7][2]
--			f[8][2] = f[6][3]*f[7][1] - f[6][1]*f[7][3]
--			f[8][3] = f[6][1]*f[7][2] - f[6][2]*f[7][1]
		end
	end
	
	--create mesh
	o.mesh = love.graphics.newMesh(atypes, #finals, "triangles", "static")
	for d,s in ipairs(finals) do
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
				s[3][1], s[3][2], s[3][3],
				s[6][1], s[6][2], s[6][3],
				s[7][1], s[7][2], s[7][3]
			)
		else
			o.mesh:setVertex(d,
				p[1], p[2], p[3], p[4] or 1.0,
				s[3][1], s[3][2], s[3][3],
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