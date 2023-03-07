---@type Dream
local lib = _3DreamEngine

---@return DreamShader
function lib:newShader()
	return setmetatable({
	}, self.meta.shader)
end

---@class DreamShader
local class = {
	links = { "shader" },
}

--todo

return class