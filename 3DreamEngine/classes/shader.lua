---@type Dream
local lib = _3DreamEngine

local lastShaderID = 0

---@param path string
---@return DreamShader
function lib:newShader(path)
	local shader = setmetatable(require(path), self.meta.shader)
	
	shader.path = path
	
	shader.id = lastShaderID
	lastShaderID = lastShaderID + 1
	
	if shader.init then
		shader:init(self)
	end
	
	return shader
end

---@class DreamShader
local class = {
	links = { "shader" },
}

return class