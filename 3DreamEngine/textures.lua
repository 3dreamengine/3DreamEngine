--[[
#part of the 3DreamEngine by Luke100000
#see init.lua for license and documentation
textures.lua - provides a lazy loading texture manager to simplify management
It can be used for other purposes than within 3Dream too.
Note that it will only load one format, if e.g. both png and jpg exists, it will automatically choose the best (lossless and fast, tga, ..., jpg)
--]]

local manager = { }

manager.textures = { }

--file type priority
manager.priorities = { }
for d,s in ipairs({"tga", "png", "gif", "bmp", "exr", "jpg", "jpe", "jpeg", "jp2"}) do
	manager.priorities[s] = d
end

--mount a directory, scan and register textures
function manager.add(self, path, name, args)
	name = name == true and (#path == 0 and "" or (path .. "/")) or name or ""
	args = args or {mipmaps = true, wrap = "repeat", filter = "linear"}
	
	for d,s in ipairs(love.filesystem.getDirectoryItems(path)) do
		if love.filesystem.getInfo(path .. "/" .. s, "directory") then
			self:add(path .. "/" .. s, (#name == 0 and s or (name .. "/" .. s)), args)
		else
			local nam = s:match("(.+)%..+") or s
			local ext = s:sub(#nam+2)
			local p = manager.priorities[ext]
			if p and (not self.textures[name .. nam] or self.textures[name .. nam].priority > p) then
				self.textures[name .. nam] = {
					path = path .. "/" .. s,
					args = args,
					priority = p,
					ext = ext,
					name = name .. nam,
				}
			end
		end
	end
end

function manager.exists(self, name)
	return self.textures[name]
end

function manager.test(self, name)
	local p1 = name .. "_simple_1"
	local p2 = name .. "_simple_2"
	local p3 = name .. "_simple_3"
	
	local t0 = self.textures[name]
	local t1 = self.textures[p1]
	local t2 = self.textures[p2]
	local t3 = self.textures[p3]
	
	return t0 or t1 or t2 or t3
end

function manager.get(self, name, lazy)
	if type(name) == "userdata" then
		return name
	end
	if self.textures[name] then
		if lazy then
			local p1 = name .. "_simple_1"
			local p2 = name .. "_simple_2"
			local p3 = name .. "_simple_3"
			
			local t0 = self.textures[name]
			local t1 = self.textures[p1]
			local t2 = self.textures[p2]
			local t3 = self.textures[p3]
			
			if t0.texture then
				return t0.texture
			elseif not t1 then
				return self:get(name)
			elseif t1.texture then
				if t0 then t0.loadNext = 3 end
				return t1.texture
			elseif not t2 then
				return self:get(p1)
			elseif t2.texture then
				if t1 then t1.loadNext = 2 end
				return t2.texture
			elseif not t3 then
				return self:get(p2)
			elseif t3.texture then
				if t2 then t2.loadNext = 1 end
				return t3.texture
			else
				return self:get(p3)
			end
		else
			if not self.textures[name].texture then
				self.textures[name].texture = love.graphics.newImage(self.textures[name].path, {mipmaps = self.textures[name].args.mipmaps})
				if self.textures[name].args.wrap then
					self.textures[name].texture:setWrap(self.textures[name].args.wrap)
				end
				if self.textures[name].args.filter then
					self.textures[name].texture:setFilter(self.textures[name].args.filter)
				end
			end
			self.textures[name].lastAccess = love.timer.getTime()
			return self.textures[name].texture
		end
	else
		return false
	end
end

function manager.update(self)
	for priority = 1, 3 do
		for d,s in pairs(self.textures) do
			if s.loadNext and not s.texture then
				if s.loadNext == priority then
					self:get(d)
					s.loadNext = false
					return true
				end
			end
		end
	end
	return false
end

return manager