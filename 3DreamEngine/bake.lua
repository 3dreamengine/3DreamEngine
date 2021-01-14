--[[
#part of the 3DreamEngine by Luke100000
bake.lua - merges several materials into one
--]]

local lib = _3DreamEngine

function lib:bakeMaterial(o)
	if not o.materials then
		return
	end
	
	--fetch all materials
	local materials = { }
	for d,s in ipairs(o.materials) do
		materials[s] = 0
	end
	
	--approximate per material area
	for d,f in ipairs(o.faces) do
		local m = o.materials[f[1]]
		
		local a = vec3(o.vertices[f[1]])
		local b = vec3(o.vertices[f[2]])
		local c = vec3(o.vertices[f[3]])
		
		local ab = b-a
		local ac = c-a
		local s = ab:cross(ac):length()/2
		
		materials[m] = materials[m] + s
	end
	
	--get UVs bounds
	local uvs = { }
	local uvo = { }
	for d,f in ipairs(o.faces) do
		local m = o.materials[f[1]]
		uvs[m] = uvs[m] or {math.huge, math.huge, -math.huge, -math.huge}
		
		local uv = {
			o.texCoords[f[1]],
			o.texCoords[f[2]],
			o.texCoords[f[3]],
		}
		
		local cx = math.floor((uv[1][1] + uv[2][1] + uv[3][1]) / 3)
		local cy = math.floor((uv[1][2] + uv[2][2] + uv[3][2]) / 3)
		uvo[f[1]] = {cx, cy}
		uvo[f[2]] = {cx, cy}
		uvo[f[3]] = {cx, cy}
		
		for v = 1, 3 do
			local a = uv[v]
			uvs[m][1] = math.min(uvs[m][1], a[1] - cx)
			uvs[m][2] = math.min(uvs[m][2], a[2] - cy)
			uvs[m][3] = math.max(uvs[m][3], a[1] - cx)
			uvs[m][4] = math.max(uvs[m][4], a[2] - cy)
		end
	end
	
	--get priority
	local totalPriority = 0
	local priority = { }
	for m,p in pairs(materials) do
		local area = math.sqrt((uvs[m][1] - uvs[m][3])^2 + (uvs[m][2] - uvs[m][4])^2)
		local textures = m.tex_albedo
		local prio = p * area * (textures and 0.001 or 1.0)
		priority[m] = prio
		totalPriority = totalPriority + prio
	end
	
	--normalize priority
	local count = 0
	local priorities = { }
	for m,p in pairs(materials) do
		priority[m] = priority[m] / totalPriority
		priorities[#priorities+1] = m
	end
	
	--aprox required subdivision counts based on priority
	local atlas = {{0, 0, 1, 0}}
	while #atlas < #priorities do
		local a = table.remove(atlas, 1)
		local h = a[3] / 2
		table.insert(atlas, {a[1], a[2], h})
		table.insert(atlas, {a[1]+h, a[2], h})
		table.insert(atlas, {a[1]+h, a[2]+h, h})
		table.insert(atlas, {a[1], a[2]+h, h})
	end
	
	--sort atlases by their size
	table.sort(atlas, function(a, b) return a[3] > b[3] end)
	
	--sort priorities
	table.sort(priorities, function(a, b) return priority[a] < priority[b] end)
	
	--insert
	for i,m in pairs(priorities) do
		atlas[i][4] = m
		atlas[m] = atlas[i]
	end
	
	--debug
	for d,s in ipairs(atlas) do
		--print(d, unpack(s))
	end
	
	--bake
	local res = 1024
	local canvases = {
		tex_albedo = love.graphics.newCanvas(res, res, {mipmaps = "manual"}),
		tex_material = love.graphics.newCanvas(res, res, {mipmaps = "manual"}),
		tex_normal = love.graphics.newCanvas(res, res, {mipmaps = "manual"}),
		tex_emission = love.graphics.newCanvas(res, res, {mipmaps = "manual"}),
	}
	local used = { }
	
	--render individual images
	for name, canvas in pairs(canvases) do
		for i = 1, canvas:getMipmapCount() do
			love.graphics.push("all")
			love.graphics.setCanvas(canvas, i)
			local w, h = canvas:getDimensions()
			love.graphics.scale(w / 2^(i-1), h / 2^(i-1))
			
			for d,s in ipairs(atlas) do
				if s[4] then
					local tex = self:getTexture(s[4][name], true)
					
					local uv = uvs[s[4]]
					local mesh = love.graphics.newMesh({
						{0, 0, uv[1], uv[2]},
						{1, 0, uv[3], uv[2]},
						{1, 1, uv[3], uv[4]},
						{0, 1, uv[1], uv[4]},
					})
					
					if name == "tex_albedo" then
						love.graphics.setColor(s[4].color)
						used[name] = true
					elseif name == "tex_material" then
						love.graphics.setColor(s[4].roughness, s[4].metallic, 1.0)
						used[name] = true
					elseif name == "tex_emission" then
						if s[4].emission then
							love.graphics.setColor(s[4].emission)
							used[name] = true
						end
					elseif tex then
						love.graphics.setColor(1, 1, 1)
						used[name] = true
					end
					
					if tex then
						mesh:setTexture(tex)
					end
					love.graphics.draw(mesh, s[1], s[2], 0, s[3])
				end
			end
			love.graphics.pop()
		end
	end
	
	--adapt UV
	local materials = { }
	for d,s in ipairs(o.texCoords) do
		local m = o.materials[d]
		local a = atlas[m]
		local uv_origin = uvo[d]
		local uv = uvs[m]
		
		local x = (s[1] - uv_origin[1] - uv[1]) / (uv[3] - uv[1])
		local y = (s[2] - uv_origin[2] - uv[2]) / (uv[4] - uv[2])
		
		o.texCoords[d] = {
			a[1] + math.clamp(x, 0, 1) * a[3],
			a[2] + math.clamp(y, 0, 1) * a[3],
		}
	end
	
	--set new material
	o.material = self:newMaterial()
	
	if used.tex_albedo then
		o.material.tex_albedo = canvases.tex_albedo
		o.material.color = {1, 1, 1, 1}
	end
	
	if used.tex_normal then
		o.material.tex_normal = canvases.tex_normal
	end
	
	if used.tex_material then
		o.material.tex_material = canvases.tex_material
		o.material.specular = 1.0
		o.material.glossiness = 1.0
		o.material.roughness = 1.0
		o.material.metallic = 1.0
	end
	
	if used.tex_emission then
		o.material.tex_emission = canvases.tex_emission
		o.material.emission = {1, 1, 1}
	end
end