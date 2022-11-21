--[[
#part of the 3DreamEngine by Luke100000
resources.lua - resource loader
--]]

local lib = _3DreamEngine

--master resource loader
lib.threads = { }

lib.texturesLoaded = { }

--start the threads (all except 2 cores planned for renderer and separate client thread)
for i = 1, math.max(1, require("love.system").getProcessorCount() - 2) do
	lib.threads[i] = love.thread.newThread(lib.root .. "/thread.lua")
	lib.threads[i]:start()
end

--input channels and result
lib.channel_busy = love.thread.getChannel("3DreamEngine_channel_jobs_channel_busy")
lib.channel_jobs = love.thread.getChannel("3DreamEngine_channel_jobs")
lib.channel_results = love.thread.getChannel("3DreamEngine_channel_results")

--returns statistics of the loader threads
function lib:getLoaderThreadUsage()
	local todo = self.channel_jobs:getCount() + self.channel_jobs:getCount()
	local working = self.channel_busy:getCount()
	local done = self.channel_results:getCount()
	return todo + working + done, todo, working, done
end

--scan for image files and adds path to image library
local imageFormats = table.toSet({ "tga", "png", "gif", "bmp", "exr", "hdr", "dds", "dxt", "pkm", "jpg", "jpe", "jpeg", "jp2" })
local images = { }
local priority = { }
local function scan(path)
	if path:sub(1, 1) ~= "." then
		for _, s in ipairs(love.filesystem.getDirectoryItems(path)) do
			if love.filesystem.getInfo(path .. "/" .. s, "directory") then
				scan(path .. (#path > 0 and "/" or "") .. s)
			else
				local name, ext = s:match("^(.+)%.(.+)$")
				if ext and imageFormats[ext] then
					local p = path .. "/" .. name
					if not images[p] or imageFormats[ext] < priority[p] then
						images[p] = path .. "/" .. s
						priority[p] = imageFormats[ext]
					end
				end
			end
		end
	end
end
scan("")

--buffer image for fastLoading
local bufferData, buffer
local fastLoadingJob = false

--updates active resource tasks (mesh loading, texture loading, ...)
function lib:update()
	--recreate buffer object if necessary
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
			
			--prepare buffer
			bufferData:paste(s.data, 0, 0, s.x * bufferSize, s.y * bufferSize, math.min(bufferSize, s.width - bufferSize * s.x), math.min(bufferSize, s.height - bufferSize * s.y))
			buffer:replacePixels(bufferData)
			
			--render
			love.graphics.push("all")
			love.graphics.reset()
			love.graphics.setBlendMode("replace", "premultiplied")
			love.graphics.setCanvas(s.canvas)
			love.graphics.draw(buffer, s.x * bufferSize, s.y * bufferSize)
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
		--image
		local width, height = msg[3]:getDimensions()
		if self.textures_smoothLoading and math.max(width, height) > bufferSize and not msg[4] then
			local canvas = love.graphics.newCanvas(width, height, { mipmaps = self.textures_mipmaps and "manual" or "none" })
			
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
			local tex = love.graphics.newImage(msg[3], { mipmaps = self.textures_mipmaps })
			
			--settings
			tex:setWrap("repeat", "repeat")
			
			--store
			self.texturesLoaded[msg[2]] = tex
		end
		
		return true
	else
		return false
	end
end

function lib:clearLoadedTextures()
	self.texturesLoaded = { }
end
function lib:clearLoadedCanvases()
	for d, s in pairs(self.texturesLoaded) do
		if type(s) == "userdata" and s:typeOf("Canvas") then
			self.texturesLoaded[d] = nil
		end
	end
end

--get image path if present
function lib:getImagePath(path)
	return images[path]
end
function lib:getImagePaths()
	return images
end

--get a texture, load it threaded if enabled and therefore may return nil first
function lib:getImage(path, force)
	if type(path) == "userdata" then
		return path
	end
	if not path then
		return false
	end
	if type(path) == "string" then
		path = {
			task = "image",
			path = path
		}
	end
	
	--skip threaded loading
	if force or not self.textures_threaded and path.task == "image" then
		if not self.texturesLoaded[path.path] then
			self.texturesLoaded[path.path] = love.graphics.newImage(path.path, { mipmaps = self.textures_mipmaps })
			self.texturesLoaded[path.path]:setWrap("repeat", "repeat")
		end
		return self.texturesLoaded[path.path]
	end
	
	--request image load
	local tex = self.texturesLoaded[path.path]
	if tex == nil then
		--mark as in progress
		self.texturesLoaded[path.path] = false
		
		--request texture load
		self.channel_jobs:push(path)
	end
	
	return tex
end

--combine 3 textures to use only one texture
function lib:combineTextures(metallic, roughness, AO)
	return {
		task = "combine",
		path = tostring(metallic) .. tostring(roughness) .. tostring(AO),
		metallic = metallic,
		roughness = roughness,
		AO = AO
	}
end