--[[
#part of the 3DreamEngine by Luke100000
loader.lua - loads objects
--]]

local lib = _3DreamEngine

--master resource loader
lib.resourceLoader = {jobs = { }, self = lib, threads = { }}

--start the threads
for i = 1, math.max(1, require("love.system").getProcessorCount()-1) do
	lib.resourceLoader.threads[i] = love.thread.newThread(lib.root .. "/thread.lua")
	lib.resourceLoader.threads[i]:start()
end

lib.resourceLoader.channel_jobs_priority = love.thread.getChannel("3DreamEngine_channel_jobs_priority")
lib.resourceLoader.channel_jobs = love.thread.getChannel("3DreamEngine_channel_jobs")
lib.resourceLoader.channel_results = love.thread.getChannel("3DreamEngine_channel_results")

--updates active resource tasks (mesh loading, texture loading, ...)
--only process one job at a time
function lib.resourceLoader.update(self)
	local msg = self.channel_results:pop()
	if msg then
		if msg[1] == "3do" then
			--3do file
			local o = self.jobs[msg[2]].objects[msg[3]]
			o.mesh = love.graphics.newMesh(o.vertexFormat, o.vertexCount, "triangles", "static")
			o.mesh:setVertexMap(o.vertexMap)
			o.mesh:setVertices(msg[4])
		else
			--image
			local tex = love.graphics.newImage(msg[2], {mipmaps = self.self.textures_mipmaps})
			tex:setWrap("repeat", "repeat")
			tex:setFilter(self.self.textures_filter, self.self.textures_filter)
			self.texturesLoaded[msg[2]] = tex
		end
		return true
	end
	return false
end

lib.resourceLoader.texturesLoaded = { }
function lib.resourceLoader.getTexture(self, path)
	if type(path) == "userdata" then
		return path
	end
	if not path then
		return false
	end
	
	--request image load, optional a thumbnail first
	local s = self.texturesLoaded[path]
	if s == nil then
		self.texturesLoaded[path] = false
		
		local ext = path:match("^.+(%..+)$") or ""
		local p = path:sub(1, #path-#ext) .. "_thumb" .. path:sub(#path-#ext+1)
		if love.filesystem.getInfo(p, "file") then
			self.channel_jobs_priority:push({"image", p})
		end
		self.channel_jobs:push({"image", path})
	end
	
	return s
end

--scan for image files
lib.imageFormats = {"tga", "png", "gif", "bmp", "exr", "jpg", "jpe", "jpeg", "jp2"}
lib.imageFormat = { }
for d,s in ipairs(lib.imageFormats) do
	lib.imageFormat["." .. s] = d
end

lib.images = {}
lib.imagesPriority = {}
local function scan(path)
	if path:sub(1, 1) ~= "." then
		for d,s in ipairs(love.filesystem.getDirectoryItems(path)) do
			if love.filesystem.getInfo(path .. "/" .. s, "directory") then
				scan(path .. "/" .. s)
			else
				local ext = s:match("^.+(%..+)$")
				if ext and lib.imageFormat[ext] then
					local p = path .. "/" .. s:sub(1, #s-#ext)
					if not lib.images[p] or lib.imageFormat[ext] < lib.imagesPriority[p] then
						lib.images[p] = path .. "/" .. s
						lib.imagesPriority[p] = lib.imageFormat[ext]
					end
				end
			end
		end
	end
end
scan("")
lib.imagesPriority = nil

--loads an object
--args is a table containing additional settings
--path is either absolute (starting from the games root dir) or relative (starting from the optional objects base dir)
--3do objects will be loaded part by part, threaded. yourObject.objects.yourMesh.mesh is nil, if its not loaded yet
function lib.loadObject(self, path, args)
	if args and type(args) ~= "table" then
		error("arguments are now packed in a table, check init.lua for example")
	end
	args = args or { }
	
	local supportedFiles = {
		"3do", --3DreamEngine object file - way faster than obj but does not keep vertex information
		"mtl", --obj material file
		"3de", --3DreamEngine information file
		"vox", --magicka voxel
		"obj", --obj file
	}
	
	--make absolute
	for _,typ in ipairs(supportedFiles) do
		if love.filesystem.getInfo(self.objectDir .. "/" .. path .. "." .. typ) then
			path = self.objectDir .. "/" .. path
			break
		end
	end
	
	--get name and dir
	local n = self:split(path, "/")
	name = n[#n] or path
	local dir = #n > 1 and table.concat(n, "/", 1, #n-1) or ""
	
	local obj = {
		materials = {None = {color = {1.0, 1.0, 1.0, 1.0}, specular = 0.5, name = "None", ID = 1}},
		materialsID = {"None"},
		objects = { },
		
		--instead of loading LIGHT_ objects as meshes, put them into the lights table for manual use and skip loading
		lights = { },
		
		path = path, --absolute path to object
		name = name, --name of object
		dir = dir, --dir containing the object
		
		--additional args settings
		noParticleSystem = args.noParticleSystem == nil and args.noMesh or args.noParticleSystem,
		
		--the object transformation
		transform = matrix{
			{1, 0, 0, 0},
			{0, 1, 0, 0},
			{0, 0, 1, 0},
			{0, 0, 0, 1},
		},
		
		self = self,
	}
	setmetatable(obj, self.operations)
	
	--merge args
	for d,s in pairs(args) do
		obj[d] = obj[d] or s
	end
	
	--load files
	--if two object files are available (.obj and .vox) it might crash, since it loads all)
	local found = false
	for _,typ in ipairs(supportedFiles) do
		local info = love.filesystem.getInfo(obj.path .. "." .. typ)
		if info then
			--check if 3do is up to date
			if typ == "3do" then
				local info2 = love.filesystem.getInfo(obj.path .. ".obj")
				local info3 = love.filesystem.getInfo(obj.path .. ".mtl")
				local info4 = love.filesystem.getInfo(obj.path .. ".3de")
				
				if info2 and info2.modtime > info.modtime or info3 and info3.modtime > info.modtime or info4 and info4.modtime > info.modtime then
					goto skip
				end
			end
			
			found = true
			
			--load most detailed/default object
			self.loader[typ](self, obj, obj.path .. "." .. typ)
			
			--skip furhter modifying and exporting if already packed as 3do
			--also skips mesh loading since it is done manually
			if typ == "3do" then
				obj.noParticleSystem = true
				obj.noMesh = true
				obj.export3do = false
				break
			end
		end
		::skip::
	end
	
	if not found then
		error("object " .. obj.name .. " not found (" .. obj.path .. ")")
	end
	
	
	--extract light sources
	for d,s in pairs(obj.objects) do
		pos = s.name:find("LAMP")
		if pos then
			local x, y, z = 0, 0, 0
			for i,v in ipairs(s.final) do
				x = x + v[1]
				y = y + v[2]
				z = z + v[3]
			end
			x = x / #s.final
			y = y / #s.final
			z = z / #s.final
			obj.lights[#obj.lights+1] = {
				name = s.name:sub(pos+5),
				x = x,
				y = y,
				z = z,
			}
			obj.objects[d] = nil
		end
	end
	
	
	--link textures to materials
	obj.textures = obj.textures or self.objectDir
	for d,s in pairs(obj.materials) do
		for _,typ in ipairs({"albedo", "normal", "roughness", "metallic", "emission", "ao"}) do
			local custom = s["tex_" .. typ]
			custom = custom and custom:match("(.+)%..+") or custom
			s["tex_" .. typ] = nil
			for _,p in pairs({
				custom,
				custom and (obj.dir .. "/" .. custom),               -- custom name, relative to object file
				obj.dir .. "/" .. obj.textures .. typ,               -- in provided directory, relative to object file
				obj.dir .. "/" .. obj.textures .. "_" .. typ,        -- as provided file, relative to object file
				self.objectDir .. "/" .. obj.textures .. typ,        -- in provided directory, relative to base dir
				self.objectDir .. "/" .. obj.textures .. "_" .. typ, -- as provided file, relative to base dir
				obj.textures .. typ,                                 -- in provided directory, relative to root
				obj.textures .. "_" .. typ,                          -- as provided file, relative to root
				
				obj.dir .. "/" .. d .. "_" .. typ,                   -- same name as material, relative to object file
				d .. "_" .. typ,                                     -- same name as material, relative to root
				obj.dir .. "/" .. obj.name .. "_" .. typ,            -- same name as object name, relative to object file
				obj.name .. "_" .. typ,                              -- same name as object name, relative to root
			}) do
				p = string.gsub("/" .. p, "//", "/")
				if p and lib.images[p] then
					s["tex_" .. typ] = lib.images[p]:sub(2)
					break
				end
			end
		end
	end
	
	
	--if raster is enabled, calculate their position in the 3D raster and move it to the center. The 'position' is the ceiled integer vertex bounding box center.
	if obj.raster then
		local rast = obj.raster == true and 1 or obj.raster
		for d,o in pairs(obj.objects) do
			local minX, maxX, minY, maxY, minZ, maxZ
			for i,v in ipairs(o.final) do
				minX = math.min(minX or v[1], v[1])
				maxX = math.max(maxX or v[1], v[1])
				minY = math.min(minY or v[2], v[2])
				maxY = math.max(maxY or v[2], v[2])
				minZ = math.min(minZ or v[3], v[3])
				maxZ = math.max(maxZ or v[3], v[3])
			end
			o.x = math.floor((((maxX or 0) + (minX or 0)) / 2 + rast/2) / rast)
			o.y = math.floor((((maxY or 0) + (minY or 0)) / 2 + rast/2) / rast)
			o.z = math.floor((((maxZ or 0) + (minZ or 0)) / 2 + rast/2) / rast)
			
			for i,v in ipairs(o.final) do
				v[1] = v[1] - o.x * rast
				v[2] = v[2] - o.y * rast
				v[3] = v[3] - o.z * rast
			end
		end
	end
	
	--grid moves all vertices so 0, 0, 0 is the floored origin with an maximal overhang of 0.25
	if obj.grid then
		for d,o in pairs(obj.objects) do
			local minX, minY, minZ
			for i,v in ipairs(o.final) do
				minX = math.min(minX or v[1], v[1])
				minY = math.min(minY or v[2], v[2])
				minZ = math.min(minZ or v[3], v[3])
			end
			o.x = math.floor((minX or 0) + 0.25)
			o.y = math.floor((minY or 0) + 0.25)
			o.z = math.floor((minZ or 0) + 0.25)
			
			for i,v in ipairs(o.final) do
				v[1] = v[1] - o.x
				v[2] = v[2] - o.y
				v[3] = v[3] - o.z
			end
		end
	end
	
	
	--create particle systems
	if not obj.noParticleSystem then
		self:addParticlesystems(obj)
	end
	
	
	--remove empty objects
	for d,s in pairs(obj.objects) do
		if s.final and #s.final == 0 then
			obj.objects[d] = nil
		end
	end
	
	
	--create meshes
	if not obj.noMesh then
		for d,o in pairs(obj.objects) do
			self:createMesh(obj, o)
		end
	end
	
	
	--cleaning up
	if not obj.noCleanup then
		for d,s in pairs(obj.objects) do
			s.faces = nil
			s.final = nil
		end
		collectgarbage()
	end
	
	
	--3do exporter
	if obj.export3do then
		function copy(first_table)
			local second_table = { }
			for k,v in pairs(first_table) do
				if type(v) == "table" then
					second_table[k] = copy(v)
				else
					second_table[k] = v
				end
			end
			return second_table
		end
		
		local compressed = "lz4"
		local compressedLevel = 9
		local meshHeaderData = { }
		local meshDataStrings = { }
		local meshDataIndex = 0
		for d,o in pairs(obj.objects) do
			if o.mesh then
				local f = o.mesh:getVertexFormat()
				meshHeaderData[d] = copy(o)
				
				meshHeaderData[d].vertexCount = o.mesh:getVertexCount()
				meshHeaderData[d].vertexMap = o.mesh:getVertexMap()
				meshHeaderData[d].vertexFormat = f
				
				meshHeaderData[d].final = nil
				meshHeaderData[d].faces = nil
				meshHeaderData[d].mesh = nil
				meshHeaderData[d].material = meshHeaderData[d].material or {color = {1.0, 1.0, 1.0, 1.0}, specular = 0.5, name = "None"}
				meshHeaderData[d].material.ID = nil
				
				local hash = love.data.encode("string", "hex", love.data.hash("md5", table.save(f)))
				local str = "typedef struct {" .. "\n"
				local count = 0
				local types = { }
				for _,ff in ipairs(f) do
					if ff[2] == "float" then
						str = str .. "float "
					elseif ff[2] == "byte" then
						str = str .. "unsigned char "
					else
						error("unknown data type " .. ff[2])
					end
					for i = 1, ff[3] do
						count = count + 1
						types[count] = ff[2]
						str = str .. "x" .. count .. (i == ff[3] and ";" or ", ")
					end
					str = str .. "\n"
				end
				str = str .. "} mesh_vertex_" .. hash .. ";"
				--print(str)
				
				--byte data
				self.ffi.cdef(str)
				local byteData = love.data.newByteData(o.mesh:getVertexCount() * self.ffi.sizeof("mesh_vertex_" .. hash))
				local meshData = self.ffi.cast("mesh_vertex_" .. hash .. "*", byteData:getPointer())
				
				--fill data
				for i = 1, o.mesh:getVertexCount() do
					local v = {o.mesh:getVertex(i)}
					for i2 = 1, count do
						meshData[i-1]["x" .. i2] = (types[i2] == "byte" and math.floor(v[i2]*255) or v[i2])
					end
				end
				
				--convert to string and store
				meshDataStrings[#meshDataStrings+1] = love.data.compress("string", compressed, byteData:getString(), compressedLevel)
				meshHeaderData[d].meshDataIndex = meshDataIndex
				meshHeaderData[d].meshDataSize = #meshDataStrings[#meshDataStrings]
				meshDataIndex = meshDataIndex + meshHeaderData[d].meshDataSize
			end
		end
		
		--export
		local headerData = love.data.compress("string", compressed, table.save(meshHeaderData), compressedLevel)
		local final = "3DO " .. compressed .. " " .. string.format("%08d", #headerData) .. headerData .. table.concat(meshDataStrings, "")
		love.filesystem.createDirectory(obj.dir)
		love.filesystem.write(obj.dir .. "/" .. obj.name .. ".3do", final)
	end
	
	
	--if raster is enabled, rename the objects to a 3 dim array based on the position calculated before
	if obj.raster then
		local objects = obj.objects
		obj.objects = { }
		for d,o in pairs(objects) do
			obj.objects[o.x] = obj.objects[o.x] or { }
			obj.objects[o.x][o.y] = obj.objects[o.x][o.y] or { }
			if obj.objects[o.x][o.y][o.z] then
				print("object atlas intersection at " .. o.x .. "*" .. o.y .. "*" .. o.z .. ": " .. d)
			end
			obj.objects[o.x][o.y][o.z] = o
		end
	end
	
	return obj
end

--takes an final and face table and generates the mesh and vertexMap
--note that .3do files has it's own mesh loader
function lib.createMesh(self, obj, o)
	--fallback material
	if not o.material then
		o.material = {color = {1.0, 1.0, 1.0, 1.0}, specular = 0.5, name = "None"}
	end
	
	--the type of the mesh determines the data the mesh contains, if not set automatically it will choose it based on textures
	o.meshType = o.meshType or obj.meshType --meshType globally set as an arg
	if not o.meshType then
		if o.material.tex_albedo then
			o.meshType = "textured"
		else
			o.meshType = "flat"
		end
	end
	
	--mesh structure
	if o.meshType == "textured" or o.meshType == "textured_array" then
		o.meshAttributes = {
		  {"VertexPosition", "float", 4},    -- x, y, z, extra
		  {"VertexTexCoord", "float", o.meshType == "textured_array" and 3 or 2},    -- UV
		  {"VertexNormal", "byte", 4},       -- normal
		  {"VertexTangent", "byte", 4},       -- normal tangent
		  {"VertexBiTangent", "byte", 4}       -- normal tangent
		}
	else
		o.meshAttributes = {
		  {"VertexPosition", "float", 4},    -- x, y, z
		  {"VertexTexCoord", "byte", 4},     -- normal, specular
		  {"VertexColor", "byte", 4},        -- color
		}
	end
	
	--remove unused finals and set up vertex map
	local vertexMap = { }
	local finals = { }
	local finalsIDs = { }
	for d,f in ipairs(o.faces) do
		for i = 1, 3 do
			if not finalsIDs[f[i]] then
				finals[#finals+1] = o.final[f[i]]
				finalsIDs[f[i]] = #finals
			end
			vertexMap[#vertexMap+1] = finalsIDs[f[i]]
		end
	end
	
	--calculate vertex normals and uv normals
	if o.meshType ~= "flat" then
		self:calcTangents(finals, vertexMap)
	end
	
	--create mesh
	o.mesh = love.graphics.newMesh(o.meshAttributes, #finals, "triangles", "static")
	
	--vertex map
	o.mesh:setVertexMap(vertexMap)
	
	--set vertices
	for d,s in ipairs(finals) do
		if o.meshType == "textured" then
			o.mesh:setVertex(d,
				s[1], s[2], s[3], s[4],
				s[9], s[10],
				s[5]*0.5+0.5, s[6]*0.5+0.5, s[7]*0.5+0.5, 0.0,
				s[11]*0.5+0.5, s[12]*0.5+0.5, s[13]*0.5+0.5, 0.0,
				s[14]*0.5+0.5, s[15]*0.5+0.5, s[16]*0.5+0.5, 0.0
			)
		elseif o.meshType == "textured_array" then
			--uses the material ID for image array index
			o.mesh:setVertex(d,
				s[1], s[2], s[3], s[4],
				s[8], s[9], s[10],
				s[5]*0.5+0.5, s[6]*0.5+0.5, s[7]*0.5+0.5, 0.0,
				s[11]*0.5+0.5, s[12]*0.5+0.5, s[13]*0.5+0.5, 0.0
			)
		elseif o.meshType == "flat" then
			local m = o.materialsID and o.materialsID[s[8]] or obj.materialsID[s[8]]
			local c = m.color or {1.0, 1.0, 1.0}
			
			o.mesh:setVertex(d,
				s[1], s[2], s[3], s[4],
				s[5]*0.5+0.5, s[6]*0.5+0.5, s[7]*0.5+0.5,
				m.specular,
				c[1], c[2], c[3], c[4]
			)
		else
			error("unknown mesh type " .. o.meshType .. ", manual mesh creating required!")
		end
	end
	
	o.mesh:flush()
end