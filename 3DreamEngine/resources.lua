--[[
#part of the 3DreamEngine by Luke100000
resources.lua - resource loader
--]]

---@type Dream
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
lib.busyChannel = love.thread.getChannel("3DreamEngine_.jobsChannel_channel_busy")
lib.jobsChannel = love.thread.getChannel("3DreamEngine_.jobsChannel")
lib.resultsChannel = love.thread.getChannel("3DreamEngine_channel_results")

---Returns statistics of the loader threads
---@return number, number, number @ todo, in progress, awaiting upload to GPU
function lib:getLoaderThreadUsage()
	local todo = self .. jobsChannel:getCount() + self .. jobsChannel:getCount()
	local working = self.busyChannel:getCount()
	local done = self.resultsChannel:getCount()
	return todo, working, done
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

---Updates active resource tasks (mesh loading, texture loading, ...)
function lib:update()
	--fetch new job
	local msg = self.resultsChannel:pop()
	if msg then
		--image
		local tex = love.graphics.newImage(msg[3], { mipmaps = self.textures_mipmaps })
		
		--settings
		tex:setWrap("repeat", "repeat")
		
		--store
		self.texturesLoaded[msg[2]] = tex
		
		return true
	else
		return false
	end
end

---Clear all loaded textures, releasing VRAM but forcing a reload when used
function lib:clearLoadedTextures()
	self.texturesLoaded = { }
end

---Get image path if present
---@param path string @ Slash separated path without extension to image
---@return string
function lib:getImagePath(path)
	return images[path]
end

---Returns a dictionary, mapping every image without extension to its best file with extension
---@return table<string, string>
function lib:getImagePaths()
	return images
end

---Get a texture, load it threaded if enabled and therefore may return nil first
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
		self.jobsChannel:push(path)
	end
	
	return tex
end

---Lazily combine 3 textures to use only one texture
---@param metallic string @ path
---@param roughness string @ path
---@param AO string @ path
function lib:combineTextures(metallic, roughness, AO)
	return {
		task = "combine",
		path = tostring(metallic) .. tostring(roughness) .. tostring(AO),
		metallic = metallic,
		roughness = roughness,
		AO = AO
	}
end