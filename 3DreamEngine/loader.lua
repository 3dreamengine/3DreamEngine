--[[
#part of the 3DreamEngine by Luke100000
loader.lua - loads objects
--]]

local lib = _3DreamEngine

--master resource loader
lib.jobs = { }
lib.threads = { }

lib.jobRenderTime = 0

--start the threads
for i = 1, math.max(1, require("love.system").getProcessorCount()-1) do
	lib.threads[i] = love.thread.newThread(lib.root .. "/thread.lua")
	lib.threads[i]:start()
end

lib.channel_jobs_priority = love.thread.getChannel("3DreamEngine_channel_jobs_priority")
lib.channel_jobs = love.thread.getChannel("3DreamEngine_channel_jobs")
lib.channel_results = love.thread.getChannel("3DreamEngine_channel_results")

--buffer image for fastLoading
local bufferSize = 128
local bufferData = love.image.newImageData(bufferSize, bufferSize)
local buffer = love.graphics.newImage(bufferData)
local fastLoadingJob = false
local performance = 3/1000
local performanceSamples = 1

local meshTypeForShaderTypes = {
	["PBR"] = "textured",
	["Phong"] = "textured",
	["color"] = "color",
	["color_extended"] = "color_extended",
	["color_material"] = "color_extended",
}

local function newBoundaryBox()
	return {
		first = vec3(math.huge, math.huge, math.huge),
		second = vec3(-math.huge, -math.huge, -math.huge),
		dimensions = vec3(0.0, 0.0, 0.0),
		center = vec3(0.0, 0.0, 0.0),
		size = 0
	}
end

--updates active resource tasks (mesh loading, texture loading, ...)
function lib.update(self, time)
	if fastLoadingJob then
		local time = math.max(0.0, (time or 3 / 1000) - performance / performanceSamples - self.jobRenderTime * 0.0)
		
		while time >= 0 and fastLoadingJob do
			local s = fastLoadingJob
			local t = love.timer.getTime()
			
			--prepare
			bufferData:paste(s.data, 0, 0, s.x*bufferSize, s.y*bufferSize, math.min(bufferSize, s.width - bufferSize*s.x), math.min(bufferSize, s.height - bufferSize*s.y))
			buffer:replacePixels(bufferData)
			
			--render
			love.graphics.push("all")
			love.graphics.reset()
			love.graphics.setBlendMode("replace", "premultiplied")
			love.graphics.setCanvas(s.canvas)
			if s.x == 0 and s.y == 0 then
				local thumbnail = self.thumbnails[s.path] and self.texturesLoaded[self.thumbnails[s.path]]
				if thumbnail then
					love.graphics.draw(thumbnail, 0, 0, 0, s.width / thumbnail:getWidth())
				else
					love.graphics.draw(buffer, 0, 0, 0, s.width / bufferSize, s.height / bufferSize)
				end
			end
			love.graphics.draw(buffer, s.x*bufferSize, s.y*bufferSize)
			love.graphics.pop()
			
			local delta = love.timer.getTime() - t
			performance = performance + delta
			performanceSamples = performanceSamples + 1
			time = time - delta
			
			if lib.textures_fastLoadingProgress then
				self.texturesLoaded[s.path] = s.canvas
			end
			
			--next chunk
			s.x = s.x + 1
			if s.x >= math.ceil(s.width / bufferSize) then
				s.x = 0
				s.y = s.y + 1
				if s.y >= math.ceil(s.height / bufferSize) then
					self.texturesLoaded[s.path] = s.canvas
					s.canvas:generateMipmaps()
					fastLoadingJob = false
				end
			end
		end
		return true
	end
	
	self.jobRenderTime = 0
	
	local msg = self.channel_results:pop()
	if msg then
		if msg[1] == "3do" then
			--3do file
			local o = self.jobs[msg[2]].objects[msg[3]]
			o.mesh = love.graphics.newMesh(o.vertexFormat, o.vertexCount, "triangles", "static")
			o.mesh:setVertexMap(o.vertexMap)
			o.mesh:setVertices(msg[4])
			
			o.vertexMap = nil
		else
			--image
			local width, height = msg[3]:getDimensions()
			if lib.textures_fastLoading and math.max(width, height) >= bufferSize * 2 then
				local canvas = love.graphics.newCanvas(width, height, {mipmaps = "manual"})
				canvas:setWrap("repeat", "repeat")
				canvas:setFilter(lib.textures_filter, lib.textures_filter)
				fastLoadingJob = {
					path = msg[2],
					canvas = canvas,
					data = msg[3],
					x = 0,
					y = 0,
					width = width,
					height = height,
				}
			else
				local tex = love.graphics.newImage(msg[3], {mipmaps = lib.textures_mipmaps})
				tex:setWrap("repeat", "repeat")
				tex:setFilter(lib.textures_filter, lib.textures_filter)
				self.texturesLoaded[msg[2]] = tex
			end
		end
		return true
	end
	return false
end

--get a texture, load it threaded and therefore may return nil first
--if a thumbnail is provided, may return the thumbnail for the first few seconds
lib.texturesLoaded = { }
lib.thumbnails = { }
function lib.getTexture(self, path)
	if type(path) == "userdata" then
		return path
	end
	if not path then
		return false
	end
	
	--request image load, optional a thumbnail first, table indicates a thread instruction, e.g. a RMA combine request
	local s = self.texturesLoaded[path] or self.thumbnails[path] and self.texturesLoaded[self.thumbnails[path]] or type(path) == "table" and self.texturesLoaded[path[2]]
	if not s and self.texturesLoaded[path] == nil then
		self.texturesLoaded[path] = false
		
		--load textures
		if type(path) == "table" then
			--advanced instructions
			if self.texturesLoaded[path[2]] == nil then
				self.texturesLoaded[path[2]] = false
				self.channel_jobs:push(path)
				path = path[2]
			else
				path = false
			end
		else
			self.channel_jobs:push({"image", path, self.textures_generateThumbnails and not path_thumb and not path_thumb_2})
		end
		
		--try to detect thumbnails
		if path then
			local ext = path:match("^.+(%..+)$") or ""
			local path_thumb = self.images[path:sub(1, #path-#ext) .. "_thumb"]
			local path_thumb_2 = self.images["thumbs/" .. path:sub(1, #path-#ext) .. "_thumb"]
			
			if path_thumb then
				self.thumbnails[path] = path_thumb
				self.channel_jobs_priority:push({"image", path_thumb})
			elseif path_thumb_2 then
				self.thumbnails[path] = path_thumb_2
				self.channel_jobs_priority:push({"image", path_thumb_2})
			end
		end
	end
	
	return s
end

--scan for image files and adds path to image library
lib.imageFormats = {"tga", "png", "gif", "bmp", "exr", "hdr", "jpg", "jpe", "jpeg", "jp2"}
lib.imageFormat = { }
for d,s in ipairs(lib.imageFormats) do
	lib.imageFormat["." .. s] = d
end

lib.images = { }
lib.imageDirectories = { }
lib.imagesPriority = { }
local function scan(path)
	if path:sub(1, 1) ~= "." then
		for d,s in ipairs(love.filesystem.getDirectoryItems(path)) do
			if love.filesystem.getInfo(path .. "/" .. s, "directory") then
				scan(path .. (#path > 0 and "/" or "") .. s)
			else
				local ext = s:match("^.+(%..+)$")
				if ext and lib.imageFormat[ext] then
					local name = s:sub(1, #s-#ext)
					local p = path .. "/" .. name
					if not lib.images[p] or lib.imageFormat[ext] < lib.imagesPriority[p] then
						lib.images[p] = path .. "/" .. s
						lib.imageDirectories[path] = lib.imageDirectories[path] or { }
						lib.imageDirectories[path][s] = path .. "/" .. s
						lib.imagesPriority[p] = lib.imageFormat[ext]
					end
				end
			end
		end
	end
end
scan("")
lib.imagesPriority = nil

--creates an empty material
function lib.newMaterial(self, name, dir)
	return {
		color = {0.5, 0.5, 0.5, 1.0}, --base color
		glossiness = 0.1,             --used for vertex color based shader
		specular = 0.5,               --used for vertex color based shader
		emission = false,             --used vertex color based shader
		alpha = false,                --decides on what pass it will go
		name = name or "None",        --name, used for texture linking
		dir = dir,                    --directory, used for texture linking
		obj = false,                  --object to which the material is assigned to. If it is false, it is most likely a public material from the material library.
		ior = 1.0,                    --used for second pass refractions, should be used on full-object glass like diamonds only, else it might reflect itself, which is incorrect
	}
end

--recognise mat files and directories with an albedo texture or "material.mat" as materials
--if the material is a directory it will skip the structured texture linking and uses the string.find to support extern material libraries
function lib.loadMaterialLibrary(self, path, prefix)
	prefix = prefix or ""
	for d,s in ipairs(love.filesystem.getDirectoryItems(path)) do
		local p = path .. "/" .. s
		
		if s:sub(#s-4) == ".mat" then
			--found material file
			local dummyObj = {materials = { }, dir = path}
			self.loader["mat"](self, dummyObj, p)
			
			--insert to material library
			for i,v in pairs(dummyObj.materials) do
				v.dir = path
				self:finishMaterial(v)
				self.materialLibrary[prefix .. i] = v
			end
		elseif love.filesystem.getInfo(p .. "/material.mat") then
			--directory is a material since it contains an anonymous material file (not nested, directly returns material without name)
			local dummyObj = {materials = { }, dir = p}
			self.loader["mat"](self, dummyObj, p .. "/material.mat", true)
			
			local mat = dummyObj.materials.material
			mat.dir = p
			self:finishMaterial(mat)
			self.materialLibrary[prefix .. s] = mat
		elseif self.imageDirectories[p] then
			--directory is a material since it contains at least one texture
			local mat = self:newMaterial(s, p)
			self:finishMaterial(mat)
			self.materialLibrary[prefix .. s] = mat
		elseif love.filesystem.getInfo(p, "directory") then
			--directory is not a material, but maybe its child directories
			self:loadMaterialLibrary(p, prefix .. s .. "/")
		end
	end
end

--link textures to material
function lib.finishMaterial(self, mat, obj)
	for _,typ in ipairs({"albedo", "normal", "roughness", "metallic", "emission", "ao", "specular", "glossiness"}) do
		local custom = mat["tex_" .. typ]
		mat["tex_" .. typ] = nil
		if custom then
			--path specified
			custom = custom and custom:match("(.+)%..+") or custom
			for _,p in pairs({
				custom,
				(mat.dir and (mat.dir .. "/") or "") .. custom,
			}) do
				if self.images[p] then
					mat["tex_" .. typ] = self.images[p]
					break
				end
			end
		elseif not obj then
			--skip matching, just look for files in same directory
			--this is a material library entry
			local images = self.imageDirectories[mat.dir]
			if images then
				for i,v in pairs(images) do
					if string.find(i, typ) then
						mat["tex_" .. typ] = v
						break
					end
				end
			end
		else
			--search for correctly named texture in the material directory
			local dir = mat.dir and (mat.dir .. "/") or ""
			for _,p in pairs({
				dir .. typ,                               -- e.g. "materialDirectory/albedo.png"
				dir .. mat.name .. "/" .. typ,            -- e.g. "materialDirectory/materialName/albedo.png"
				dir .. mat.name .. "_" .. typ,            -- e.g. "materialDirectory/materialName_albedo.png"
				dir .. obj.name .. "_" .. typ,      	  -- e.g. "materialDirectory/objectName_albedo.png"
			}) do
				if self.images[p] then
					mat["tex_" .. typ] = self.images[p]
					break
				end
			end
		end
	end
	
	if not mat["tex_" .. "combined"] then
		local metallicRoughness = mat["tex_metallic"] or mat["tex_roughness"]
		local specularGlossiness = mat["tex_specular"] or mat["tex_glossiness"]
		
		if metallicRoughness or specularGlossiness or mat["tex_ao"] then
			if metallicRoughness then
				mat["tex_" .. "combined"] = self:combineTextures(mat["tex_roughness"], mat["tex_metallic"], mat["tex_ao"])
			elseif specularGlossiness then
				mat["tex_" .. "combined"] = self:combineTextures(mat["tex_glossiness"], mat["tex_specular"], mat["tex_ao"])
			end
		end
	end
end

function lib.combineTextures(self, metallicSpecular, roughnessGlossines, AO, name)
	local path = (metallicSpecular or roughnessGlossines or (AO .. "combined")):gsub("metallic", "combined"):gsub("roughness", "combined"):gsub("specular", "combined"):gsub("glossiness", "combined")
	
	if name then
		local dir = path:match("(.*[/\\])")
		path = dir and (dir .. name) or name
	else
		path = path:match("(.+)%..+")
	end
	
	return {"combine", path, metallicSpecular, roughnessGlossines, AO}
end

--loads an object
--args is a table containing additional settings
--path is the absolute path without extension
--3do objects will be loaded part by part, threaded. yourObject.objects.yourMesh.mesh is nil, if its not loaded yet
function lib.loadObject(self, path, args)
	if args and type(args) ~= "table" then
		error("arguments are now packed in a table, check init.lua for example")
	end
	args = args or { }
	
	local supportedFiles = {
		"mtl", --obj material file
		"mat", --3DreamEngine material file
		"3do", --3DreamEngine object file - way faster than obj but does not keep vertex information
		"vox", --magicka voxel
		"obj", --obj file
	}
	
	--get name and dir
	local n = self:split(path, "/")
	name = n[#n] or path
	local dir = #n > 1 and table.concat(n, "/", 1, #n-1) or ""
	
	local obj = {
		materials = {
			None = args.material or self:newMaterial()
		},
		objects = { },
		positions = { },
		
		path = path, --absolute path to object
		name = name, --name of object
		dir = dir, --dir containing the object
		
		--additional args settings
		noParticleSystem = args.noParticleSystem == nil and args.noMesh or args.noParticleSystem,
		
		--the object transformation
		transform = mat4:getIdentity(),
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
				if args.skip3do then
					goto skip
				end
				
				local info2 = love.filesystem.getInfo(obj.path .. ".obj")
				if info2 and info2.modtime > info.modtime then
					goto skip
				end
			end
			
			found = true
			
			--load object
			local failed = self.loader[typ](self, obj, obj.path .. "." .. typ)
			
			--look for collision
			if typ == "obj" then
				if love.filesystem.getInfo(obj.path .. "_collision." .. typ) then
					self.loader[typ](self, obj, obj.path .. "_collision." .. typ, true)
				end
			end
			
			--skip furhter modifying and exporting if already packed as 3do
			--also skips mesh loading since it is done manually
			if typ == "3do" and not failed then
				obj.noParticleSystem = true
				obj.noMesh = true
				obj.export3do = false
				obj.centerMass = false
				obj.grid = false
				break
			end
		end
		::skip::
	end
	
	if not found then
		error("object " .. obj.name .. " not found (" .. obj.path .. ")")
	end
	
	
	--extract positions
	for d,s in pairs(obj.objects) do
		local pos = s.name:find("POS")
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
			
			local r = 0
			for i,v in ipairs(s.final) do
				r = r + math.sqrt((v[1] - x)^2 + (v[2] - y)^2 + (v[3] - z)^2)
			end
			r = r / #s.final
			
			local stop = s.name:find(".", pos, true)
			obj.positions[#obj.positions+1] = {
				name = s.name:sub(pos+4, stop and (stop - 1) or #s.name),
				size = r,
				x = x,
				y = y,
				z = z,
			}
			obj.objects[d] = nil
		end
	end
	
	
	--disable objects
	for d,o in pairs(obj.objects) do
		local pos = o.name:find("DISABLED")
		if pos then
			o.disabled = true
		end
	end
	
	--grid moves all vertices in a way that 0, 0, 0 is the floored origin with an maximal overhang of 0.25 units.
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
	
	--move object to its center of vertice mass
	if obj.centerMass then
		for d,o in pairs(obj.objects) do
			if not (d:sub(1, 10) == "COLLISION_" and obj.objects[d:sub(11)]) then
				local x, y, z = 0, 0, 0
				for i,v in ipairs(o.final) do
					x = x + v[1]
					y = y + v[2]
					z = z + v[3]
				end
				
				o.cx = x / #o.final
				o.cy = y / #o.final
				o.cz = z / #o.final
				
				for i,v in ipairs(o.final) do
					v[1] = v[1] - o.cx
					v[2] = v[2] - o.cy
					v[3] = v[3] - o.cz
				end
			end
		end
	end
	
	--use mass center of collisions actual mesh
	if obj.centerMass then
		for d,o in pairs(obj.objects) do
			if d:sub(1, 10) == "COLLISION_" and obj.objects[d:sub(11)] then
				local o2 = obj.objects[d:sub(11)]
				o.cx = o2.cx
				o.cy = o2.cy
				o.cz = o2.cz
				for i,v in ipairs(o.final) do
					v[1] = v[1] - o.cx
					v[2] = v[2] - o.cy
					v[3] = v[3] - o.cz
				end
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
	
	
	--extract collisions
	for dd,s in pairs(obj.objects) do
		local pos = s.name:find("COLLISION")
		if pos then
			local d = #s.name:sub(pos + 10) == 0 and "collision" or s.name:sub(pos + 10)
			obj.collisions = obj.collisions or { }
			obj.collisionCount = (obj.collisionCount or 0) + 1
			obj.collisions[d] = {
				name = obj.name,
				faces = { },
				normals = { },
				edges = { },
				point = vec3(0, 0, 0),
				boundary = 0,
			}
			local n = obj.collisions[d]
			
			local function hash(a, b)
				return math.min(a, b) * 9999 + math.max(a, b)
			end
			
			local hashes = { }
			local f = s.final
			
			for d,s in ipairs(s.faces) do
				local a, b, c = f[s[1]], f[s[2]], f[s[3]]
				
				n.point = a
				
				--face normal
				table.insert(n.normals, vec3(a[5]+b[5]+c[5], a[6]+b[6]+c[6], a[7]+b[7]+c[7]):normalize())
				
				a = vec3(a[1], a[2], a[3])
				b = vec3(b[1], b[2], b[3])
				c = vec3(c[1], c[2], c[3])
				
				--boundary
				n.boundary = math.max(n.boundary, a:length(), b:length(), c:length())
				
				--face
				table.insert(n.faces, {a, b, c})
				
				--edges
				local id
				id = hash(s[1], s[2])
				if not hashes[id] then
					table.insert(n.edges, {a, b})
					hashes[id] = true
				end
				
				id = hash(s[1], s[3])
				if not hashes[id] then
					table.insert(n.edges, {a,c })
					hashes[id] = true
				end
				
				id = hash(s[2], s[3])
				if not hashes[id] then
					table.insert(n.edges, {b, c})
					hashes[id] = true
				end
			end
			obj.objects[dd] = nil
		end
	end
	
	
	--post load materials
	for d,s in pairs(obj.materials) do
		s.dir = s.dir or obj.textures or dir
		self:finishMaterial(s, obj)
	end
	
	
	--create meshes
	if not obj.noMesh then
		for d,o in pairs(obj.objects) do
			if not o.disabled then
				o.shaderType = nil
				self:createMesh(obj, o)
			end
		end
	end
	
	
	--calculate bounding box
	obj.boundingBox = newBoundaryBox()
	local total = 0
	for d,s in pairs(obj.objects) do
		total = total + 1
		if s.boundingBox then
			--convert loaded boundaries (e.g. .3do files)
			s.boundingBox.first = vec3(s.boundingBox.first)
			s.boundingBox.second = vec3(s.boundingBox.first)
			s.boundingBox.dimensions = vec3(s.boundingBox.first)
			s.boundingBox.center = vec3(s.boundingBox.first)
		else
			s.boundingBox = newBoundaryBox()
			
			--scan all vertices
			for i,v in ipairs(s.final) do
				local pos = vec3(v)
				s.boundingBox.first = s.boundingBox.first:min(pos)
				s.boundingBox.second = s.boundingBox.second:max(pos)
				s.boundingBox.center = s.boundingBox.center + pos
			end
			
			s.boundingBox.center = s.boundingBox.center / #s.final
			s.boundingBox.dimensions = s.boundingBox.second - s.boundingBox.first
			s.boundingBox.size = math.max((s.boundingBox.dimensions * 0.5):length(), s.boundingBox.size)
		end
		
		obj.boundingBox.first = s.boundingBox.first:min(obj.boundingBox.first)
		obj.boundingBox.second = s.boundingBox.second:max(obj.boundingBox.second)
		obj.boundingBox.center = s.boundingBox.center + obj.boundingBox.center
		
		obj.boundingBox.size = math.max(obj.boundingBox.size, s.boundingBox.size)
	end
	obj.boundingBox.center = obj.boundingBox.center / total
	obj.boundingBox.dimensions = obj.boundingBox.second - obj.boundingBox.first
	
	
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
		function copy(first_table, skip)
			local second_table = { }
			for k,v in pairs(first_table) do
				if type(v) == "table" then
					if not skip[v] then
						second_table[k] = copy(v, skip)
					end
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
				meshHeaderData[d] = copy(o, {[o.material or false] = true, [o.final or false] = true, [o.faces or false] = true, [o.mesh or false] = true})
				
				meshHeaderData[d].vertexCount = o.mesh:getVertexCount()
				meshHeaderData[d].vertexMap = o.mesh:getVertexMap()
				meshHeaderData[d].vertexFormat = f
				meshHeaderData[d].material = o.material.name
				
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
		local final = "3DO1" .. compressed .. " " .. string.format("%08d", #headerData) .. headerData .. table.concat(meshDataStrings, "")
		love.filesystem.createDirectory(obj.dir)
		love.filesystem.write(obj.dir .. "/" .. obj.name .. ".3do", final)
	end
	
	return obj
end

--takes an final and face table and generates the mesh and vertexMap
--note that .3do files has it's own mesh loader
function lib.createMesh(self, obj, o)
	o = o or obj
	
	--the type of the mesh determines the data the mesh contains, if not set automatically it will choose it based on textures
	o.meshType = o.meshType or obj.meshType
	o.shaderType = o.shaderType or obj.shaderType
	
	--guess shaderType if not specified based on textures used
	if not o.shaderType then
		o.shaderType = "color_extended"
		
		local s = o.material
		if s.tex_albedo or s.tex_normal then
			o.shaderType = lib.lighting_engine
		end
	end
	
	--determine required mesh data for selected material shader
	o.meshType = o.meshType or meshTypeForShaderTypes[o.shaderType] or "textured"
	if meshTypeForShaderTypes[o.shaderType] and meshTypeForShaderTypes[o.shaderType] ~= o.meshType then
		print("shader " .. o.shaderType .. " is not designed for mesh type " .. o.meshType .. "!")
	end
	
	--mesh structure
	local requireTangents = false
	if o.meshType == "textured" then
		requireTangents = true
		o.meshAttributes = {
		  {"VertexPosition", "float", 4},     -- x, y, z, extra
		  {"VertexTexCoord", "float", 2},     -- UV
		  {"VertexNormal", "byte", 4},        -- normal
		  {"VertexTangent", "byte", 4},       -- normal tangent
		  {"VertexBiTangent", "byte", 4}      -- normal tangent
		}
	elseif o.meshType == "textured_array" then
		requireTangents = true
		o.meshAttributes = {
		  {"VertexPosition", "float", 4},     -- x, y, z, extra
		  {"VertexTexCoord", "float", 3},     -- UV
		  {"VertexNormal", "byte", 4},        -- normal
		  {"VertexTangent", "byte", 4},       -- normal tangent
		  {"VertexBiTangent", "byte", 4}      -- normal tangent
		}
	elseif o.meshType == "color" then
		o.meshAttributes = {
		  {"VertexPosition", "float", 4},    -- x, y, z, extra
		  {"VertexTexCoord", "byte", 4},     -- normal, specular
		  {"VertexColor", "byte", 4},        -- color
		}
	elseif o.meshType == "color_extended" then
		o.meshAttributes = {
		  {"VertexPosition", "float", 4},    -- x, y, z, extra
		  {"VertexTexCoord", "float", 3},    -- normal
		  {"VertexMaterial", "float", 3},    -- specular, glossiness, emissive
		  {"VertexColor", "byte", 4},        -- color
		}
	else
		error("unknown mesh type " .. tostring(o.meshType))
	end
	
	--remove unused finals, merge finals and set up vertex map
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
	if requireTangents then
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
			o.mesh:setVertex(d,
				s[1], s[2], s[3], s[4],
				s[9], s[10], s[8],
				s[5]*0.5+0.5, s[6]*0.5+0.5, s[7]*0.5+0.5, 0.0,
				s[11]*0.5+0.5, s[12]*0.5+0.5, s[13]*0.5+0.5, 0.0,
				s[14]*0.5+0.5, s[15]*0.5+0.5, s[16]*0.5+0.5, 0.0
			)
		elseif o.meshType == "color" then
			local c = s[8].color
			o.mesh:setVertex(d,
				s[1], s[2], s[3], s[4],
				s[5]*0.5+0.5, s[6]*0.5+0.5, s[7]*0.5+0.5,
				s[8].specular,
				c[1], c[2], c[3], c[4]
			)
		elseif o.meshType == "color_extended" then
			local c = s[8].color
			o.mesh:setVertex(d,
				s[1], s[2], s[3], s[4],
				s[5], s[6], s[7],
				s[8].specular, s[8].glossiness, s[8].emission or 0.0,
				c[1], c[2], c[3], c[4]
			)
		end
	end
end