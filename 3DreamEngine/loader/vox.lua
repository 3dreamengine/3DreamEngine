--[[
#vox - MagicaVoxel
supports the vox extension
--]]

local ffi = require("ffi")

local default = {
	0x00000000, 0xffffffff, 0xffccffff, 0xff99ffff, 0xff66ffff, 0xff33ffff, 0xff00ffff, 0xffffccff, 0xffccccff, 0xff99ccff, 0xff66ccff, 0xff33ccff, 0xff00ccff, 0xffff99ff, 0xffcc99ff, 0xff9999ff,
	0xff6699ff, 0xff3399ff, 0xff0099ff, 0xffff66ff, 0xffcc66ff, 0xff9966ff, 0xff6666ff, 0xff3366ff, 0xff0066ff, 0xffff33ff, 0xffcc33ff, 0xff9933ff, 0xff6633ff, 0xff3333ff, 0xff0033ff, 0xffff00ff,
	0xffcc00ff, 0xff9900ff, 0xff6600ff, 0xff3300ff, 0xff0000ff, 0xffffffcc, 0xffccffcc, 0xff99ffcc, 0xff66ffcc, 0xff33ffcc, 0xff00ffcc, 0xffffcccc, 0xffcccccc, 0xff99cccc, 0xff66cccc, 0xff33cccc,
	0xff00cccc, 0xffff99cc, 0xffcc99cc, 0xff9999cc, 0xff6699cc, 0xff3399cc, 0xff0099cc, 0xffff66cc, 0xffcc66cc, 0xff9966cc, 0xff6666cc, 0xff3366cc, 0xff0066cc, 0xffff33cc, 0xffcc33cc, 0xff9933cc,
	0xff6633cc, 0xff3333cc, 0xff0033cc, 0xffff00cc, 0xffcc00cc, 0xff9900cc, 0xff6600cc, 0xff3300cc, 0xff0000cc, 0xffffff99, 0xffccff99, 0xff99ff99, 0xff66ff99, 0xff33ff99, 0xff00ff99, 0xffffcc99,
	0xffcccc99, 0xff99cc99, 0xff66cc99, 0xff33cc99, 0xff00cc99, 0xffff9999, 0xffcc9999, 0xff999999, 0xff669999, 0xff339999, 0xff009999, 0xffff6699, 0xffcc6699, 0xff996699, 0xff666699, 0xff336699,
	0xff006699, 0xffff3399, 0xffcc3399, 0xff993399, 0xff663399, 0xff333399, 0xff003399, 0xffff0099, 0xffcc0099, 0xff990099, 0xff660099, 0xff330099, 0xff000099, 0xffffff66, 0xffccff66, 0xff99ff66,
	0xff66ff66, 0xff33ff66, 0xff00ff66, 0xffffcc66, 0xffcccc66, 0xff99cc66, 0xff66cc66, 0xff33cc66, 0xff00cc66, 0xffff9966, 0xffcc9966, 0xff999966, 0xff669966, 0xff339966, 0xff009966, 0xffff6666,
	0xffcc6666, 0xff996666, 0xff666666, 0xff336666, 0xff006666, 0xffff3366, 0xffcc3366, 0xff993366, 0xff663366, 0xff333366, 0xff003366, 0xffff0066, 0xffcc0066, 0xff990066, 0xff660066, 0xff330066,
	0xff000066, 0xffffff33, 0xffccff33, 0xff99ff33, 0xff66ff33, 0xff33ff33, 0xff00ff33, 0xffffcc33, 0xffcccc33, 0xff99cc33, 0xff66cc33, 0xff33cc33, 0xff00cc33, 0xffff9933, 0xffcc9933, 0xff999933,
	0xff669933, 0xff339933, 0xff009933, 0xffff6633, 0xffcc6633, 0xff996633, 0xff666633, 0xff336633, 0xff006633, 0xffff3333, 0xffcc3333, 0xff993333, 0xff663333, 0xff333333, 0xff003333, 0xffff0033,
	0xffcc0033, 0xff990033, 0xff660033, 0xff330033, 0xff000033, 0xffffff00, 0xffccff00, 0xff99ff00, 0xff66ff00, 0xff33ff00, 0xff00ff00, 0xffffcc00, 0xffcccc00, 0xff99cc00, 0xff66cc00, 0xff33cc00,
	0xff00cc00, 0xffff9900, 0xffcc9900, 0xff999900, 0xff669900, 0xff339900, 0xff009900, 0xffff6600, 0xffcc6600, 0xff996600, 0xff666600, 0xff336600, 0xff006600, 0xffff3300, 0xffcc3300, 0xff993300,
	0xff663300, 0xff333300, 0xff003300, 0xffff0000, 0xffcc0000, 0xff990000, 0xff660000, 0xff330000, 0xff0000ee, 0xff0000dd, 0xff0000bb, 0xff0000aa, 0xff000088, 0xff000077, 0xff000055, 0xff000044,
	0xff000022, 0xff000011, 0xff00ee00, 0xff00dd00, 0xff00bb00, 0xff00aa00, 0xff008800, 0xff007700, 0xff005500, 0xff004400, 0xff002200, 0xff001100, 0xffee0000, 0xffdd0000, 0xffbb0000, 0xffaa0000,
	0xff880000, 0xff770000, 0xff550000, 0xff440000, 0xff220000, 0xff110000, 0xffeeeeee, 0xffdddddd, 0xffbbbbbb, 0xffaaaaaa, 0xff888888, 0xff777777, 0xff555555, 0xff444444, 0xff222222, 0xff111111
}

local palette = { }
for i = 1, 255 do
	palette[i] = {
		math.floor(default[i]) % 256,
		math.floor(default[i] / 256) % 256,
		math.floor(default[i] / 256^2) % 256,
		math.floor(default[i] / 256^3) % 256,
	}
end

return function(self, obj, path)
	local file = love.filesystem.read(path)
	
	local function parseInt(i)
		return string.byte(file:sub(i+1, i+1)) + string.byte(file:sub(i+2, i+2)) * 256 + string.byte(file:sub(i+3, i+3)) * 256^2 + string.byte(file:sub(i+4, i+4)) * 256^3
	end

	local int32 = 2^32
	local function parseInt32(i)
		local v = parseInt(i)
		if v >= int32/2 then
			v = int32 - v - 2
		end
		return v
	end

	local function parseString(i)
		local length = parseInt32(i)
		return file:sub(i+5, i+5+length-1), length
	end

	local function parseDICT(i)
		local i2 = 0
		local count = parseInt32(i)
		local t = { }
		for c = 1, count do
			local key, length = parseString(i+i2+4)
			i2 = i2 + length
			local value, length = parseString(i+i2+8)
			i2 = i2 + length
			
			i2 = i2 + 8
			t[key] = value
		end
		return t, i2
	end
	
	local typ = file:sub(1, 4)
	assert(typ == "VOX ", "invalid vox file")
	local version = parseInt(4)
	
	local materials = { }
	
	local nodes = { }
	local groups = { }
	
	local modelCount = 1
	local models = { }
	local currModel
	local i = 8
	while true do
		local chunk = file:sub(i+1, i+4)
		if #chunk ~= 4 then
			break
		end
		
		local length = parseInt(i+4)
		local length_children = parseInt(i+8)
		
		if chunk == "MAIN" then
			
		elseif chunk == "PACK" then
			modelCount = parseInt(i+12)
		elseif chunk == "SIZE" then
			local x = parseInt(i+12)
			local y = parseInt(i+16)
			local z = parseInt(i+20)
			
			--create new model
			currModel = {x = x, y = y, z = z, blocks = ffi.new("uint8_t[" .. x .. "][" .. y .. "][" .. z .. "]")}
			table.insert(models, currModel)
			for xx = 0, x-1 do
				for yy = 0, y-1 do
					for zz = 0, z-1 do
						currModel.blocks[xx][yy][zz] = 0
					end
				end
			end
		elseif chunk == "XYZI" then
			local count = parseInt(i+12)
			for c = 1, count do
				local x = string.byte(file:sub(i+16+(c-1)*4+1, i+16+(c-1)*4+1))
				local y = string.byte(file:sub(i+16+(c-1)*4+2, i+16+(c-1)*4+2))
				local z = string.byte(file:sub(i+16+(c-1)*4+3, i+16+(c-1)*4+3))
				local i = string.byte(file:sub(i+16+(c-1)*4+4, i+16+(c-1)*4+4))
				currModel.blocks[x][y][z] = i
			end
		elseif chunk == "RGBA" then
			for c = 1, 255 do
				palette[i] = {
					string.byte(file:sub(i+12+(c-1)*4+1, i+12+(c-1)*4+1)),
					string.byte(file:sub(i+12+(c-1)*4+2, i+12+(c-1)*4+2)),
					string.byte(file:sub(i+12+(c-1)*4+3, i+12+(c-1)*4+3)),
					string.byte(file:sub(i+12+(c-1)*4+4, i+12+(c-1)*4+4)),
				}
			end
		elseif chunk == "MATT" then
			--not supported, deprecated
		elseif chunk == "nTRN" then
			local id = parseInt32(i+12)
			local att, i2 = parseDICT(i+16)
			local childId = parseInt32(i+i2+20)
			local reserved = parseInt32(i+i2+24) --must be -1
			local layerId = parseInt32(i+i2+28)
			local frameCount = parseInt32(i+i2+32) --must be 1
			
			if reserved ~= -1 or frameCount ~= 1 then
				print(reserved, frameCount)
				print("unsupported vox file, reserved or frameCount in use, should be -1 / 1, trying to continue.")
			end
			
			nodes[id] = {id = id, childId = childId, nodeAttributes = att, attributes = parseDICT(i+i2+36), children = { }}
			if nodes[id].attributes._t then
				nodes[id].transform = string.split(nodes[id].attributes._t, " ")
				for cc = 1, 3 do
					nodes[id].transform[cc] = tonumber(nodes[id].transform[cc]) or 0
				end
			end
		elseif chunk == "nGRP" then
			local id = parseInt32(i+12)
			local att, i2 = parseDICT(i+16)
			local children = parseInt32(i+i2+20)
			
			groups[id] = { }
			for c = 1, children do
				local cId = parseInt32(i+i2+24 + (c-1)*4)
				table.insert(groups[id], cId)
			end
		elseif chunk == "nSHP" then
			local id = parseInt32(i+12)
			local att, i2 = parseDICT(i+16)
			local num = parseInt32(i+i2+20)
			
			if num ~= 1 then
				print("invalid vox file, more than one model per shape, trying to continue")
			end
			
			nodes[id] = {id = id, nodeAttributes = att, modelId = parseInt32(i+i2+24), modelAttributes = parseDICT(i+i2+28)}
		elseif chunk == "LAYR" then
			--not required
		elseif chunk == "rOBJ" then
			--the heck is this?
		elseif chunk == "MATL" then
			local id = parseInt32(i+12)
			local mat = parseDICT(i+16)
			local color = palette[id] or {0, 0, 0}
			materials[id] = self:newMaterial()
			materials[id].color = color
			materials[id].roughness = mat._rough
			materials[id].metallic = mat._type == "_metal" and 1 or 0
			materials[id].ior = mat._type == "_glass" and mat._ior or 1.0
			materials[id].emission = {mat._flux, mat._flux, mat._flux}
			materials[id].name = tostring(id)
		else
			print("unknown chunk " .. chunk)
		end
		
		i = i + length + 12
	end
	
	local function add(o, x, y, z, nx, ny, nz, mat)
		table.insert(o.vertices, {x, y, z})
		table.insert(o.normals, {nx, ny, nz})
		table.insert(o.colors, mat.color)
		table.insert(o.roughnesses, mat.roughness)
		table.insert(o.metallics, mat.metallic)
		table.insert(o.emissions, mat.emission)
	end
	
	--generate final object
	local function generate(m, name, t)
		local material = self:newMaterial()
		material:setPixelShader("simple")
		local o = self:newMesh(name, material)
		obj.meshes[name] = o
		
		for x = 0, m.x-1 do
			for y = 0, m.y-1 do
				for z = 0, m.z-1 do
					local b = m.blocks[x][y][z]
					if b > 0 then
						local ox = t[1] + x
						local oy = t[3] + z
						local oz = t[2] + y
						
						local mat = materials[b]
						
						--top
						if z == 0 or m.blocks[x][y][z-1] == 0 then
							add(o, ox+0, oy+0, oz+1, 0, -1, 0, mat)
							add(o, ox+1, oy+0, oz+1, 0, -1, 0, mat)
							add(o, ox+1, oy+0, oz+0, 0, -1, 0, mat)
							add(o, ox+0, oy+0, oz+0, 0, -1, 0, mat)
							local c = #o.vertices
							table.insert(o.faces, {c-0, c-1, c-2})
							table.insert(o.faces, {c-0, c-2, c-3})
						end
						
						--bottom
						if z == m.z-1 or m.blocks[x][y][z+1] == 0 then
							add(o, ox+0, oy+1, oz+0, 0, 1, 0, mat)
							add(o, ox+1, oy+1, oz+0, 0, 1, 0, mat)
							add(o, ox+1, oy+1, oz+1, 0, 1, 0, mat)
							add(o, ox+0, oy+1, oz+1, 0, 1, 0, mat)
							local c = #o.vertices
							table.insert(o.faces, {c-0, c-1, c-2})
							table.insert(o.faces, {c-0, c-2, c-3})
						end
						
						--right
						if x == 0 or m.blocks[x-1][y][z] == 0 then
							add(o, ox+0, oy+1, oz+0, -1, 0, 0, mat)
							add(o, ox+0, oy+1, oz+1, -1, 0, 0, mat)
							add(o, ox+0, oy+0, oz+1, -1, 0, 0, mat)
							add(o, ox+0, oy+0, oz+0, -1, 0, 0, mat)
							local c = #o.vertices
							table.insert(o.faces, {c-0, c-1, c-2})
							table.insert(o.faces, {c-0, c-2, c-3})
						end
						
						--left
						if x == m.x-1 or m.blocks[x+1][y][z] == 0 then
							add(o, ox+1, oy+0, oz+0, 1, 0, 0, mat)
							add(o, ox+1, oy+0, oz+1, 1, 0, 0, mat)
							add(o, ox+1, oy+1, oz+1, 1, 0, 0, mat)
							add(o, ox+1, oy+1, oz+0, 1, 0, 0, mat)
							local c = #o.vertices
							table.insert(o.faces, {c-0, c-1, c-2})
							table.insert(o.faces, {c-0, c-2, c-3})
						end
						
						--front
						if y == 0 or m.blocks[x][y-1][z] == 0 then
							add(o, ox+0, oy+0, oz+0, 0, 0, -1, mat)
							add(o, ox+1, oy+0, oz+0, 0, 0, -1, mat)
							add(o, ox+1, oy+1, oz+0, 0, 0, -1, mat)
							add(o, ox+0, oy+1, oz+0, 0, 0, -1, mat)
							local c = #o.vertices
							table.insert(o.faces, {c-0, c-1, c-2})
							table.insert(o.faces, {c-0, c-2, c-3})
						end
						
						--back
						if y == m.y-1 or m.blocks[x][y+1][z] == 0 then
							add(o, ox+0, oy+1, oz+1, 0, 0, 1, mat)
							add(o, ox+1, oy+1, oz+1, 0, 0, 1, mat)
							add(o, ox+1, oy+0, oz+1, 0, 0, 1, mat)
							add(o, ox+0, oy+0, oz+1, 0, 0, 1, mat)
							local c = #o.vertices
							table.insert(o.faces, {c-0, c-1, c-2})
							table.insert(o.faces, {c-0, c-2, c-3})
						end
					end
				end
			end
		end
	end
	
	local function group(g, t, name)
		if g.childId then
			if groups[g.childId] then
				for d,s in ipairs(groups[g.childId]) do
					group(nodes[s], t)
				end
			else
				t = {t[1], t[2], t[3]}
				t[1] = t[1] + g.transform[1]
				t[2] = t[2] + g.transform[2]
				t[3] = t[3] + g.transform[3]
				
				group(nodes[g.childId], t, g.nodeAttributes._name)
			end
		else
			local m = g.modelId
			generate(models[m+1], name or tostring(m), t)
		end
	end
	
	--hard coded offset
	group(nodes[0], {0, 0, 0})
end