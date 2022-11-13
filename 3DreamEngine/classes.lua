--[[
#part of the 3DreamEngine by Luke100000
classes.lua - contains meta tables and constructors for all 3Dream classes
--]]

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

--final meta tables
lib.meta = { }
for name, class in pairs(lib.classes) do
	class.link = { }
	if class.links then
		lib.meta[name] = link(class.links)
		for _, meta in pairs(class.links) do
			class.link[meta] = true
		end
	end
end