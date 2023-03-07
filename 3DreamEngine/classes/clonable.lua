---@class DreamClonable
local class = {
	links = { },
}

---Slow and deep clone
function class:clone()
	local n = { }
	
	for key, value in pairs(self) do
		if type(value) == "table" and type(value.clone) == "function" then
			n[key] = value:clone()
		else
			n[key] = value
		end
	end
	
	return setmetatable(n, getmetatable(self))
end

---Creates an fast instance
function class:instance()
	return setmetatable({}, { __index = self })
end

return class