--[[
#part of the 3DreamEngine by Luke100000
resources.lua - resource loader
--]]

local lib = _3DreamEngine

--master resource loader
lib.resourceJobs = { }
lib.threads = { }

--start the threads
for i = 1, math.max(1, require("love.system").getProcessorCount()-1) do
	lib.threads[i] = love.thread.newThread(lib.root .. "/thread.lua")
	lib.threads[i]:start()
end

lib.channel_jobs_priority = love.thread.getChannel("3DreamEngine_channel_jobs_priority")
lib.channel_jobs = love.thread.getChannel("3DreamEngine_channel_jobs")
lib.channel_results = love.thread.getChannel("3DreamEngine_channel_results")

--buffer image for fastLoading
local bufferData, buffer
local fastLoadingJob = false

--updates active resource tasks (mesh loading, texture loading, ...)
function lib.update(self, time)
	local bufferSize = self.textures_bufferSize
	if not bufferData or bufferData:getWidth() ~= self.textures_bufferSize then
		bufferData = love.image.newImageData(bufferSize, bufferSize)
		buffer = love.graphics.newImage(bufferData)
	end
	
	--process current image
	if fastLoadingJob then
		local time = self.textures_smoothLoadingTime
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
			love.graphics.draw(buffer, s.x*bufferSize, s.y*bufferSize)
			love.graphics.pop()
			
			--next chunk
			s.x = s.x + 1
			if s.x >= math.ceil(s.width / bufferSize) then
				s.x = 0
				s.y = s.y + 1
				if s.y >= math.ceil(s.height / bufferSize) then
					--accept as fully loaded
					self.texturesLoaded[s.path] = s.canvas
					
					--force mipmap generation
					if s.canvas:getMipmapCount() > 1 then
						s.canvas:generateMipmaps()
					end
					
					--delete thumbnail since it is no longer required
					if self.thumbnailPaths[s.path] then
						self.texturesLoaded[self.thumbnailPaths[s.path]] = nil
					end
					
					--close job
					fastLoadingJob = false
				end
			end
			
			--time required
			local delta = love.timer.getTime() - t
			time = time - delta
		end
		return true
	end
	
	--fetch new job
	local msg = self.channel_results:pop()
	if msg then
		if msg[1] == "3do" then
			--3do mesh data
			local o = self.resourceJobs[msg[2]].objects[msg[3]]
			o.mesh = love.graphics.newMesh(o.vertexFormat, o.vertexCount, "triangles", "static")
			o.mesh:setVertexMap(o.vertexMap)
			o.mesh:setVertices(msg[4])
			o.vertexMap = nil
		else
			--image
			local width, height = msg[3]:getDimensions()
			if self.textures_smoothLoading and math.max(width, height) > bufferSize and not msg[4] then
				local canvas = love.graphics.newCanvas(width, height, {mipmaps = self.textures_mipmaps and "manual" or "none"})
				
				--settings
				canvas:setWrap("repeat", "repeat")
				
				--prepare loading job
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
				local tex = love.graphics.newImage(msg[3], {mipmaps = self.textures_mipmaps})
				
				--settings
				tex:setWrap("repeat", "repeat")
				
				--store
				self.texturesLoaded[msg[2]] = tex
				
				--clear thumbnail
				if self.thumbnailPaths[msg[2]] then
					self.texturesLoaded[self.thumbnailPaths[msg[2]]] = nil
				end
			end
		end
		return true
	end
	return false
end

--get a texture, load it threaded if enabled and therefore may return nil first
--if a thumbnail is provided, may return the thumbnail until fully loaded
lib.texturesLoaded = { }
lib.thumbnailPaths = { }
function lib:getTexture(path)
	if type(path) == "userdata" then
		return path
	end
	if not path then
		return false
	end
	
	--skip threaded loading
	if not self.textures_threaded and type(path) == "string" then
		if not self.texturesLoaded[path] then
			self.texturesLoaded[path] = love.graphics.newImage(path)
		end
		return self.texturesLoaded[path]
	end
	
	--request image load, optional a thumbnail first, table indicates a thread instruction, e.g. a RMA combine request
	local tex = self.texturesLoaded[path] or self.thumbnailPaths[path] and self.texturesLoaded[self.thumbnailPaths[path]] or type(path) == "table" and self.texturesLoaded[path[2]]
	if not tex and self.texturesLoaded[path] == nil then
		--mark as in progress
		self.texturesLoaded[path] = false
		
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
			--request texture load
			self.channel_jobs:push({"image", path, self.textures_generateThumbnails})
		end
		
		--try to detect thumbnails
		if path then
			local ext = path:match("^.+(%..+)$") or ""
			local path_thumb = self.images[path:sub(1, #path-#ext) .. "_thumb"]
			local path_thumb_cached = self.images["thumbs/" .. path:sub(1, #path-#ext) .. "_thumb"]
			
			--also request thumbnail in the priority channel
			if path_thumb then
				self.thumbnailPaths[path] = path_thumb
				self.channel_jobs_priority:push({"image", path_thumb})
			elseif path_thumb_cached then
				self.thumbnailPaths[path] = path_thumb_cached
				self.channel_jobs_priority:push({"image", path_thumb_cached})
			end
		end
	end
	
	return tex
end

--scan for image files and adds path to image library
local imageFormats = {"tga", "png", "gif", "bmp", "exr", "hdr", "dds", "dxt", "pkm", "jpg", "jpe", "jpeg", "jp2"}
local imageFormat = { }
for d,s in ipairs(imageFormats) do
	imageFormat["." .. s] = d
end

lib.images = { }
lib.imageDirectories = { }
local priority = { }
local function scan(path)
	if path:sub(1, 1) ~= "." then
		for d,s in ipairs(love.filesystem.getDirectoryItems(path)) do
			if love.filesystem.getInfo(path .. "/" .. s, "directory") then
				scan(path .. (#path > 0 and "/" or "") .. s)
			else
				local ext = s:match("^.+(%..+)$")
				if ext and imageFormat[ext] then
					local name = s:sub(1, #s-#ext)
					local p = path .. "/" .. name
					if not lib.images[p] or imageFormat[ext] < priority[p] then
						lib.images[p] = path .. "/" .. s
						lib.imageDirectories[path] = lib.imageDirectories[path] or { }
						lib.imageDirectories[path][s] = path .. "/" .. s
						priority[p] = imageFormat[ext]
					end
				end
			end
		end
	end
end
scan("")

--combine 3 textures to use only one texture
function lib:combineTextures(metallicSpecular, roughnessGlossines, AO, name)
	local path = (metallicSpecular or roughnessGlossines or (AO .. "combined")):gsub("metallic", "combined"):gsub("roughness", "combined"):gsub("specular", "combined"):gsub("glossiness", "combined")
	
	if name then
		local dir = path:match("(.*[/\\])")
		path = dir and (dir .. name) or name
	else
		path = path:match("(.+)%..+")
	end
	
	return {"combine", path, metallicSpecular, roughnessGlossines, AO}
end