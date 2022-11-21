---@class DreamClonable
local class = {
	links = { },
}

---Clone
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

return class