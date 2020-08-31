--[[
#part of the 3DreamEngine by Luke100000
resources.lua - resource loader
--]]

local lib = _3DreamEngine

--master resource loader
lib.jobs = { }
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
local bufferSize = 128
local bufferData = love.image.newImageData(bufferSize, bufferSize)
local buffer = love.graphics.newImage(bufferData)
local fastLoadingJob = false
local performance = 3/1000
local performanceSamples = 1

--updates active resource tasks (mesh loading, texture loading, ...)
function lib.update(self, time)
	--process current image
	if fastLoadingJob then
		local time = math.max(0.0, (time or 3 / 1000) - performance / performanceSamples)
		
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
			
			if self.textures_fastLoadingProgress then
				self.texturesLoaded[s.path] = s.canvas
			end
			
			--next chunk
			s.x = s.x + 1
			if s.x >= math.ceil(s.width / bufferSize) then
				s.x = 0
				s.y = s.y + 1
				if s.y >= math.ceil(s.height / bufferSize) then
					self.texturesLoaded[s.path] = s.canvas
					if s.canvas:getMipmapCount() > 1 then
						s.canvas:generateMipmaps()
					end
					if self.thumbnails[s.path] then
						self.texturesLoaded[self.thumbnails[s.path]] = nil
					end
					fastLoadingJob = false
				end
			end
		end
		return true
	end
	
	--fetch new job
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
			if self.textures_fastLoading and math.max(width, height) >= bufferSize * 2 and not msg[4] then
				local canvas = love.graphics.newCanvas(width, height, {mipmaps = self.textures_mipmaps and "manual" or "none"})
				
				--settings
				canvas:setWrap("repeat", "repeat")
				canvas:setFilter(self.textures_filter, self.textures_filter)
				if canvas:getMipmapCount() > 1 then
					canvas:setMipmapFilter(self.textures_filter)
				end
				
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
				tex:setFilter(self.textures_filter, self.textures_filter)
				if tex:getMipmapCount() > 1 then
					tex:setMipmapFilter(self.textures_filter)
				end
				
				--store
				self.texturesLoaded[msg[2]] = tex
				
				--clear thumbnail
				if self.thumbnails[msg[2]] then
					self.texturesLoaded[self.thumbnails[msg[2]]] = nil
				end
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
lib.imageFormats = {"tga", "png", "gif", "bmp", "exr", "hdr", "dds", "dxt", "pkm", "jpg", "jpe", "jpeg", "jp2"}
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