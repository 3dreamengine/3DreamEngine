---@type Dream
local lib = _3DreamEngine

function lib:newBone(id, transform)
	local b = {
		id = id,
		transform = transform,
		children = { },
	}
	
	return setmetatable(b, self.meta.bone)
end

---@class DreamBone : DreamClonable, DreamIsNamed
---@field public transform DreamMat4
---@field public children table<string, DreamBone>
local class = {
	links = { "bone", "clonable" },
}

return class