--[[
#part of the 3DreamEngine by Luke100000
classes.lua - contains meta tables and constructors for all 3Dream classes
--]]

---@type Dream
local lib = _3DreamEngine

lib.classes = { }
for _, s in pairs(love.filesystem.getDirectoryItems(lib.root .. "/classes")) do
	local name = s:sub(1, #s - 4)
	lib.classes[name] = require(lib.root .. "/classes/" .. name)
	lib.classes[name].class = name
end

--link several metatables together
local function link(chain)
	local m = { }
	for _, meta in pairs(chain) do
		for name, func in pairs(lib.classes[meta]) do
			m[name] = func
		end
	end
	return { __index = m, __tostring = m.tostring }
end

local function gatherLinks(class, links)
	if class.links then
		for _, meta in pairs(class.links) do
			if meta ~= class.class then
				gatherLinks(lib.classes[meta], links)
			end
		end
	end
	table.insert(links, class.class)
end

--final meta tables
lib.meta = { }
for name, class in pairs(lib.classes) do
	class.link = { }
	if class.links then
		local links = { }
		gatherLinks(class, links)
		lib.meta[name] = link(links)
		for _, meta in pairs(class.links) do
			class.link[meta] = true
		end
	end
end