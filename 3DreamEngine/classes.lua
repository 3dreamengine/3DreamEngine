--[[
#part of the 3DreamEngine by Luke100000
classes.lua - contains meta tables and constructors for all 3Dream classes
--]]

local lib = _3DreamEngine

lib.classes = { }
for d,s in pairs(love.filesystem.getDirectoryItems(lib.root .. "/classes")) do
	local name = s:sub(1, #s-4)
	lib.classes[name] = require(lib.root .. "/classes/" .. name)
	lib.classes[name].class = name
end

--link several metatables together
local function link(chain)
	local m = { }
	for _,meta in pairs(chain) do
		for name, func in pairs(lib.classes[meta]) do
			m[name] = func
		end
	end
	return {__index = m, __tostring = m.tostring}
end

--auto create setter and getter
for d,s in pairs(lib.classes) do
	if s.setterGetter then
		for name, typ in pairs(s.setterGetter) do
			local n = name:sub(1, 1):upper() .. name:sub(2)
			
			if not s["set" .. n] then
				s["set" .. n] = function(self, value)
					assert(type(value) == typ, typ .. " expected, got " .. type(value))
					self[name] = value
				end
			end
			
			if typ == "boolean" then
				if not s["is" .. n] and not s["get" .. n] then
					s["is" .. n] = function(self)
						return self[name]
					end
				end
			else
				if not s["get" .. n] then
					s["get" .. n] = function(self)
						return self[name]
					end
				end
			end
		end
	end
end

--final meta tables
lib.meta = { }
for d,s in pairs(lib.classes) do
	if s.link then
		lib.meta[d] = link(s.link)
	end
end