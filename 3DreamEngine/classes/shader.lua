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
	
	shader:init(self)
	
	return shader
end

---@class DreamShader
local class = {
	links = { "shader" },
}

function class:init()

end

function class:getId(mat, shadow)
	return 0
end

function class:buildFlags(mat, shadow)
	return ""
end

function class:buildDefines(mat, shadow)
	return ""
end

function class:buildPixel(mat)
	return ""
end

function class:buildVertex(mat)
	return ""
end

function class:perShader(shaderObject)

end

function class:perMaterial(shaderObject, material)

end

function class:perTask(shaderObject, task)

end

return class